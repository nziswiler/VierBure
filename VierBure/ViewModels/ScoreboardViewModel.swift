import Foundation
import SwiftUI
import Combine

@MainActor
final class ScoreboardViewModel: ObservableObject {
    @Published private(set) var players: [Player] = []
    @Published private(set) var rounds: Int = 0
    @Published private(set) var allPlayerNames: [String] = []
    @Published var selectedCell: SelectedCell?

    private let dataManager: GameDataManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    struct SelectedCell: Equatable {
        let round: Int
        let playerIndex: Int
    }

    init(dataManager: GameDataManagerProtocol = GameDataManager()) {
        self.dataManager = dataManager
        setupInitialState()
        setupAutoSave()
    }

    private func setupInitialState() {
        allPlayerNames = dataManager.loadPlayerNames()

        if let savedState = dataManager.loadGameState() {
            loadGameState(savedState)
        } else {
            initializeNewGame()
        }
    }

    private func setupAutoSave() {
        // Auto-save when game state changes
        Publishers.CombineLatest3($players, $rounds, $allPlayerNames)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] players, rounds, names in
                self?.saveCurrentState()
            }
            .store(in: &cancellables)
    }

    private func loadGameState(_ state: GameState) {
        players = state.players
        rounds = state.rounds
        setPlayerCount(state.activePlayerCount)
    }

    private func initializeNewGame(playerCount: Int = 4) {
        let count = max(GameConstants.minPlayers, min(GameConstants.maxPlayers, playerCount))
        players = (0..<count).map { index in
            Player(name: allPlayerNames[index])
        }
        rounds = 0
        ensureScoreCapacity()
    }

    private func saveCurrentState() {
        let state = GameState(
            players: players,
            rounds: rounds,
            activePlayerCount: players.count
        )
        dataManager.saveGameState(state)
        dataManager.savePlayerNames(allPlayerNames)
    }

    private func ensureScoreCapacity() {
        for i in players.indices {
            players[i].ensureScoreCapacity(for: rounds)
        }
    }

    // MARK: - Public Interface

    func setPlayerCount(_ count: Int) {
        let validCount = max(GameConstants.minPlayers, min(GameConstants.maxPlayers, count))

        if validCount > players.count {
            // Add new players
            let newPlayers = (players.count..<validCount).map { index in
                var player = Player(name: allPlayerNames[index])
                player.ensureScoreCapacity(for: rounds)
                return player
            }
            players.append(contentsOf: newPlayers)
        } else if validCount < players.count {
            // Remove players
            players = Array(players.prefix(validCount))
        }

        selectedCell = nil
    }

    func addRound() {
        rounds += 1
        ensureScoreCapacity()
    }

    func removeLastRound() {
        if rounds > 0 {
            rounds -= 1
            ensureScoreCapacity()
        }
    }

    func resetGame() {
        rounds = 0
        for i in players.indices {
            players[i].scores = []
        }
        selectedCell = nil
        dataManager.clearGameData()
    }

    func updatePlayerName(_ name: String, at index: Int) {
        // Allow spaces and empty names while editing; defaults are applied on Done in NamesSheet
        let finalName = String(name.prefix(10))

        // Ensure allPlayerNames can hold this index
        if allPlayerNames.count <= index {
            let needed = index + 1 - allPlayerNames.count
            let start = allPlayerNames.count
            for i in 0..<needed {
                let j = start + i
                let defaultName: String
                if j < GameConstants.defaultPlayerNames.count {
                    defaultName = GameConstants.defaultPlayerNames[j]
                } else {
                    defaultName = "Spieler \(j + 1)"
                }
                allPlayerNames.append(defaultName)
            }
        }

        // Update the stored name (can be empty while editing)
        allPlayerNames[index] = finalName

        // If the player exists in the active list, update the visible name as well
        if players.indices.contains(index) {
            players[index].name = finalName
        }
    }

    func updateTopScore(_ value: String, round: Int, playerIndex: Int) {
        guard let result = ScoreValidator.validateTopScore(value) else { return }

        switch result {
        case .success(let score):
            if players.indices.contains(playerIndex) && players[playerIndex].scores.indices.contains(round) {
                players[playerIndex].scores[round].top = score
            }
        case .failure(let error):
            // Handle error (could show alert or similar)
            print("Score validation error: \(error.localizedDescription)")
        }
    }

    func selectCell(round: Int, playerIndex: Int) {
        selectedCell = SelectedCell(round: round, playerIndex: playerIndex)
    }

    func clearSelection() {
        selectedCell = nil
    }

    // MARK: - Score Operations

    func adjustBottomScore(by delta: Int) {
        guard let selected = selectedCell,
              players.indices.contains(selected.playerIndex),
              selected.round < players[selected.playerIndex].scores.count else { return }

        let currentValue = players[selected.playerIndex].scores[selected.round].bottom ?? 0
        players[selected.playerIndex].scores[selected.round].bottom = currentValue + delta
    }

    func clearBottomScore() {
        guard let selected = selectedCell,
              players.indices.contains(selected.playerIndex),
              selected.round < players[selected.playerIndex].scores.count else { return }

        players[selected.playerIndex].scores[selected.round].bottom = nil
    }

    func fillTopScoreToTotal() {
        guard let selected = selectedCell else { return }

        let totalOthers = players.enumerated().reduce(0) { sum, element in
            let (index, player) = element
            guard index != selected.playerIndex,
                  selected.round < player.scores.count else { return sum }
            return sum + (player.scores[selected.round].top ?? 0)
        }

        let remainder = max(0, GameConstants.totalPointsPerRound - totalOthers)
        players[selected.playerIndex].scores[selected.round].top = remainder
    }

    func setTopScoreToMatch() {
        guard let selected = selectedCell,
              players.indices.contains(selected.playerIndex),
              selected.round < players[selected.playerIndex].scores.count else { return }

        players[selected.playerIndex].scores[selected.round].top = GameConstants.matchValue
    }

    // MARK: - Computed Properties

    var playerTotals: [Int] {
        players.map(\.totalScore)
    }

    func isRoundEditable(_ round: Int) -> Bool {
        round == rounds - 1
    }

    func isRoundValid(_ round: Int) -> Bool {
        // Only validate completed rounds
        guard round < rounds - 1 else { return true }

        // Check if any player has a match
        let hasMatch = players.contains { player in
            guard round < player.scores.count else { return false }
            return player.scores[round].top == GameConstants.matchValue
        }

        if hasMatch { return true }

        // Check if top scores sum to 157
        let totalTop = players.reduce(0) { sum, player in
            guard round < player.scores.count else { return sum }
            return sum + (player.scores[round].top ?? 0)
        }

        return totalTop == GameConstants.totalPointsPerRound
    }

    func topScoreBinding(round: Int, playerIndex: Int) -> Binding<String> {
        Binding<String>(
            get: {
                guard self.players.indices.contains(playerIndex),
                      round < self.players[playerIndex].scores.count,
                      let value = self.players[playerIndex].scores[round].top else {
                    return "0"
                }
                return String(value)
            },
            set: { newValue in
                self.updateTopScore(newValue, round: round, playerIndex: playerIndex)
            }
        )
    }

    func bottomScore(round: Int, playerIndex: Int) -> Int? {
        guard players.indices.contains(playerIndex),
              round < players[playerIndex].scores.count else { return nil }
        return players[playerIndex].scores[round].bottom
    }
}
