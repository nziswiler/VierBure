import Foundation

struct RoundScore: Hashable, Codable {
    var top: Int?
    var bottom: Int?

    init(top: Int? = nil, bottom: Int? = nil) {
        self.top = top
        self.bottom = bottom
    }

    var total: Int {
        (top ?? 0) + (bottom ?? 0)
    }

    var isEmpty: Bool {
        top == nil && bottom == nil
    }

    var hasTopValue: Bool {
        top != nil
    }

    var hasBottomValue: Bool {
        bottom != nil
    }
}

extension RoundScore {
    static let empty = RoundScore()

    func with(top newTop: Int?) -> RoundScore {
        RoundScore(top: newTop, bottom: bottom)
    }

    func with(bottom newBottom: Int?) -> RoundScore {
        RoundScore(top: top, bottom: newBottom)
    }
}