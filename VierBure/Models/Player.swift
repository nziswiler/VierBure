import Foundation

struct Player: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var scores: [RoundScore]

    init(name: String, scores: [RoundScore] = []) {
        self.id = UUID()
        self.name = name
        self.scores = scores
    }

    var totalScore: Int {
        scores.reduce(0) { $0 + $1.total }
    }

    func score(for round: Int) -> RoundScore? {
        guard scores.indices.contains(round) else { return nil }
        return scores[round]
    }

    mutating func setScore(_ score: RoundScore, for round: Int) {
        guard scores.indices.contains(round) else { return }
        scores[round] = score
    }

    mutating func ensureScoreCapacity(for rounds: Int) {
        if scores.count < rounds {
            let needed = rounds - scores.count
            scores.append(contentsOf: Array(repeating: .empty, count: needed))
        } else if scores.count > rounds {
            scores = Array(scores.prefix(rounds))
        }
    }
}

extension Player {
    static func defaultPlayer(index: Int) -> Player {
        Player(name: "Spieler \(index + 1)")
    }
}