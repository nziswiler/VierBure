import Foundation

enum GameConstants {
    static let totalPointsPerRound = 157
    static let matchValue = -257
    static let minPlayers = 3
    static let maxPlayers = 6
    static let maxDigitsPerScore = 3
    static let maxScoreValue = 999
    static let minScoreValue = -999

    static let defaultPlayerNames = [
        "Spieler 1", "Spieler 2", "Spieler 3",
        "Spieler 4", "Spieler 5", "Spieler 6"
    ]

    static let scoreIncrements = [20, 50, 100, 150]
    static let scoreDecrements = [-20, -50, -100, -150]
}

enum GameError: LocalizedError {
    case invalidPlayerCount
    case invalidRoundNumber
    case invalidScoreValue
    case dataCorruption

    var errorDescription: String? {
        switch self {
        case .invalidPlayerCount:
            return "Player count must be between \(GameConstants.minPlayers) and \(GameConstants.maxPlayers)"
        case .invalidRoundNumber:
            return "Invalid round number"
        case .invalidScoreValue:
            return "Score value must be between \(GameConstants.minScoreValue) and \(GameConstants.maxScoreValue)"
        case .dataCorruption:
            return "Game data appears to be corrupted"
        }
    }
}