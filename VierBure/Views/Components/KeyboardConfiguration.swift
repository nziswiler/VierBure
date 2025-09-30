import SwiftUI

struct KeyboardConfiguration {
    let spacing: CGFloat
    let keyHeight: CGFloat
    let digitKeyHeight: CGFloat
    let cornerRadius: CGFloat
    let containerPadding: CGFloat
    let digitFont: Font
    let keyFont: Font

    init(width: CGFloat) {
        switch width {
        case ..<340:  // iPhone SE
            spacing = 4
            keyHeight = 48
            digitKeyHeight = 44
            cornerRadius = 8
            containerPadding = 8
            digitFont = .system(size: 18, weight: .medium, design: .rounded)
            keyFont = .system(size: 15, weight: .medium)
        case ..<390:  // Standard iPhone
            spacing = 6
            keyHeight = 52
            digitKeyHeight = 44
            cornerRadius = 10
            containerPadding = 12
            digitFont = .system(size: 20, weight: .medium, design: .rounded)
            keyFont = .system(size: 16, weight: .medium)
        case ..<768:  // Large iPhone
            spacing = 8
            keyHeight = 56
            digitKeyHeight = 44
            cornerRadius = 12
            containerPadding = 16
            digitFont = .system(size: 22, weight: .medium, design: .rounded)
            keyFont = .system(size: 17, weight: .medium)
        default:      // iPad
            spacing = 10
            keyHeight = 64
            digitKeyHeight = 48
            cornerRadius = 14
            containerPadding = 20
            digitFont = .system(size: 24, weight: .medium, design: .rounded)
            keyFont = .system(size: 18, weight: .medium)
        }
    }

    func calculateTotalHeight() -> CGFloat {
        let rows: CGFloat = 4
        let spacingBetweenRows = spacing * (rows - 1)
        let totalKeyHeight = digitKeyHeight + (keyHeight * 3)
        let totalPadding = containerPadding * 2
        let extraSpacing: CGFloat = 24 // Additional spacing for better layout

        return totalKeyHeight + spacingBetweenRows + totalPadding + extraSpacing
    }
}