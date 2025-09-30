import Foundation

protocol GameDataManagerProtocol {
    func loadPlayerNames() -> [String]
    func savePlayerNames(_ names: [String])
    func loadGameState() -> GameState?
    func saveGameState(_ state: GameState)
    func clearGameData()
}

final class GameDataManager: GameDataManagerProtocol {
    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let playerNames = "Scoreboard.PlayerNames"
        static let gameState = "Scoreboard.GameState"
    }

    func loadPlayerNames() -> [String] {
        let saved = userDefaults.stringArray(forKey: Keys.playerNames) ?? []
        var names = saved

        // Ensure we always have exactly 6 names
        while names.count < GameConstants.maxPlayers {
            names.append(GameConstants.defaultPlayerNames[names.count])
        }

        if names.count > GameConstants.maxPlayers {
            names = Array(names.prefix(GameConstants.maxPlayers))
        }

        return names
    }

    func savePlayerNames(_ names: [String]) {
        let validNames = Array(names.prefix(GameConstants.maxPlayers))
        userDefaults.set(validNames, forKey: Keys.playerNames)
    }

    func loadGameState() -> GameState? {
        guard let data = userDefaults.data(forKey: Keys.gameState) else { return nil }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(GameState.self, from: data)
        } catch {
            print("Failed to decode game state: \(error)")
            return nil
        }
    }

    func saveGameState(_ state: GameState) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(state)
            userDefaults.set(data, forKey: Keys.gameState)
        } catch {
            print("Failed to encode game state: \(error)")
        }
    }

    func clearGameData() {
        userDefaults.removeObject(forKey: Keys.gameState)
    }
}

struct GameState: Codable {
    let players: [Player]
    let rounds: Int
    let activePlayerCount: Int
    let lastModified: Date

    init(players: [Player], rounds: Int, activePlayerCount: Int) {
        self.players = players
        self.rounds = rounds
        self.activePlayerCount = activePlayerCount
        self.lastModified = Date()
    }
}