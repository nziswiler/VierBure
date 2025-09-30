import SwiftUI

struct TotalsRow: View {
    let totals: [Int]
    let playerNames: [String]

    private var maxTotal: Int {
        totals.max() ?? 0
    }

    private var minTotal: Int {
        totals.min() ?? 0
    }

    private var allZero: Bool {
        totals.allSatisfy { $0 == 0 }
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 20)
                .frame(width: 20)

            HStack(spacing: 6) {
                ForEach(Array(totals.enumerated()), id: \.offset) { index, total in
                    TotalCell(
                        total: total,
                        isWinning: !allZero && total == minTotal,
                        isLosing: !allZero && total == maxTotal,
                        playerName: playerNames.indices.contains(index) ?
                            playerNames[index] : "Spieler \(index + 1)"
                    )
                }
            }

            Spacer(minLength: 20)
                .frame(width: 20)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Gesamtpunkte")
    }
}

private struct TotalCell: View {
    let total: Int
    let isWinning: Bool
    let isLosing: Bool
    let playerName: String

    var body: some View {
        Text("\(total)")
            .font(.body.monospacedDigit().weight(.semibold))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
            )
            .accessibilityLabel("\(playerName): \(total) Punkte")
            .accessibilityAddTraits(accessibilityTraits)
    }

    private var textColor: Color {
        if isWinning {
            return .green
        } else if isLosing {
            return .red
        } else {
            return .primary
        }
    }

    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = []
        if isWinning {
            _ = traits.insert(.isSelected)
        }
        return traits
    }
}