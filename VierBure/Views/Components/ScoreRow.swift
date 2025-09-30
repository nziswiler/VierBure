import SwiftUI

struct ScoreRow: View {
    let round: Int
    @ObservedObject var viewModel: ScoreboardViewModel
    let onError: (String) -> Void

    private var isEditable: Bool {
        viewModel.isRoundEditable(round)
    }

    private var isValid: Bool {
        viewModel.isRoundValid(round)
    }

    private var isCompleted: Bool {
        !isEditable && isValid && round < viewModel.rounds - 1
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundNumberIndicator(
                number: round + 1,
                isEditable: isEditable,
                isValid: isValid
            )

            HStack(spacing: 6) {
                ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { playerIndex, _ in
                    ScoreCell(
                        topText: viewModel.topScoreBinding(
                            round: round,
                            playerIndex: playerIndex
                        ),
                        isEnabled: isEditable,
                        bottomValue: viewModel.bottomScore(
                            round: round,
                            playerIndex: playerIndex
                        ),
                        isSelected: isSelected(playerIndex: playerIndex),
                        onSelect: {
                            viewModel.selectCell(round: round, playerIndex: playerIndex)
                        },
                        onPlus20: { viewModel.adjustBottomScore(by: 20) },
                        onPlus50: { viewModel.adjustBottomScore(by: 50) },
                        onPlus100: { viewModel.adjustBottomScore(by: 100) },
                        onMinus20: { viewModel.adjustBottomScore(by: -20) },
                        onMinus50: { viewModel.adjustBottomScore(by: -50) },
                        onMinus100: { viewModel.adjustBottomScore(by: -100) },
                        onClear: { viewModel.clearBottomScore() },
                        onRest: { viewModel.fillTopScoreToTotal() },
                        onMatch: { viewModel.setTopScoreToMatch() },
                        onDone: { viewModel.clearSelection() }
                    )
                    .frame(maxWidth: .infinity)
                }
            }

            RoundStatusIndicator(
                isEditable: isEditable,
                isValid: isValid,
                isCompleted: isCompleted
            )
        }
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(backgroundStyle)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func isSelected(playerIndex: Int) -> Bool {
        guard let selected = viewModel.selectedCell else { return false }
        return selected.round == round && selected.playerIndex == playerIndex
    }

    private var backgroundStyle: some ShapeStyle {
        if !isValid {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.06),
                        Color.red.opacity(0.02)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ).opacity(0.7)
            )
        }
        return AnyShapeStyle(Color.clear)
    }

    private var accessibilityLabel: String {
        if !isValid {
            return "Runde \(round + 1): Fehler - Summe oben ist nicht \(GameConstants.totalPointsPerRound)"
        } else if isCompleted {
            return "Runde \(round + 1): Korrekt abgeschlossen"
        } else if isEditable {
            return "Runde \(round + 1): Aktive Runde - kann bearbeitet werden"
        }
        return "Runde \(round + 1)"
    }
}

private struct RoundNumberIndicator: View {
    let number: Int
    let isEditable: Bool
    let isValid: Bool

    var body: some View {
        Text("\(number)")
            .font(.caption2.weight(isValid ? .regular : .semibold))
            .foregroundStyle(textColor)
            .frame(width: 20, alignment: .center)
    }

    private var textColor: Color {
        if !isValid {
            return .red
        } else if !isEditable && isValid {
            return .green
        } else if isEditable {
            return .blue
        } else {
            return .secondary
        }
    }
}

private struct RoundStatusIndicator: View {
    let isEditable: Bool
    let isValid: Bool
    let isCompleted: Bool

    var body: some View {
        ZStack {
            if !isValid {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)
                    .opacity(0.9)
                    .transition(.opacity)
            } else if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.green)
                    .opacity(0.8)
                    .transition(.opacity)
            } else if isEditable {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.blue)
                    .opacity(0.8)
                    .transition(.opacity)
            }
        }
        .frame(width: 20, alignment: .center)
        .animation(.easeInOut(duration: 0.2), value: isValid)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
        .animation(.easeInOut(duration: 0.2), value: isEditable)
    }
}