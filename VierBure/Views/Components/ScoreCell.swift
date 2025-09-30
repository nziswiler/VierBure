import SwiftUI

struct ScoreCell: View {
    @Binding var topText: String
    let isEnabled: Bool
    let bottomValue: Int?
    let isSelected: Bool
    let onSelect: () -> Void

    let onPlus20: () -> Void
    let onPlus50: () -> Void
    let onPlus100: () -> Void
    let onMinus20: () -> Void
    let onMinus50: () -> Void
    let onMinus100: () -> Void
    let onClear: () -> Void
    let onRest: () -> Void
    let onMatch: () -> Void
    let onDone: () -> Void

    @State private var shouldFocus = false

    var body: some View {
        VStack(spacing: 4) {
            ScoreTextField(
                text: $topText,
                shouldFocus: $shouldFocus,
                isEnabled: isEnabled,
                onSelect: onSelect,
                onPlus20: onPlus20,
                onPlus50: onPlus50,
                onPlus100: onPlus100,
                onMinus20: onMinus20,
                onMinus50: onMinus50,
                onMinus100: onMinus100,
                onClearBottom: onClear,
                onRest: onRest,
                onMatch: onMatch,
                onDone: onDone
            )
            .frame(maxWidth: .infinity)

            Text("\(bottomValue ?? 0)")
                .font(.caption2.monospacedDigit())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.secondary.opacity(0.06))
                )
        }
        .padding(6)
        .opacity(isEnabled ? 1 : 0.6)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.25),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .onTapGesture {
            if isEnabled {
                shouldFocus = true
                onSelect()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isEnabled ? .isButton : [])
        .accessibilityLabel("Score cell")
        .accessibilityValue("Top: \(topText), Bottom: \(bottomValue ?? 0)")
    }
}