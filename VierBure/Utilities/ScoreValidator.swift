import Foundation

enum ScoreValidator {
    enum ValidationResult {
        case success(Int)
        case failure(GameError)
    }

    static func validateTopScore(_ input: String) -> ValidationResult? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle empty input
        if trimmed.isEmpty {
            return .success(0)
        }

        // Try to parse as integer
        guard let value = Int(trimmed) else {
            return .failure(.invalidScoreValue)
        }

        // Check bounds
        let clamped = max(GameConstants.minScoreValue, min(GameConstants.maxScoreValue, value))
        return .success(clamped)
    }

    static func validatePlayerName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "" : trimmed
    }

    static func validatePlayerCount(_ count: Int) -> Int {
        return max(GameConstants.minPlayers, min(GameConstants.maxPlayers, count))
    }

    static func isValidRoundSum(_ scores: [Int?], allowMatch: Bool = true) -> Bool {
        // Check for match value
        if allowMatch && scores.contains(GameConstants.matchValue) {
            return true
        }

        let sum = scores.compactMap { $0 }.reduce(0, +)
        return sum == GameConstants.totalPointsPerRound
    }
}