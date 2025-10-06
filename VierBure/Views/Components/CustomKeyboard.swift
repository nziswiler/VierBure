import SwiftUI

struct CustomKeyboard: View {
    let onDigit: (Int) -> Void
    let onDelete: () -> Void
    let onPlus20: () -> Void
    let onPlus50: () -> Void
    let onPlus100: () -> Void
    let onMinus20: () -> Void
    let onMinus50: () -> Void
    let onMinus100: () -> Void
    let onClearBottom: () -> Void
    let onRest: () -> Void
    let onMatch: () -> Void
    let onDone: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let config = KeyboardConfiguration(width: proxy.size.width)

            VStack(spacing: config.spacing) {
                numberRow(config: config)
                plusRow(config: config)
                minusRow(config: config)
                actionRow(config: config)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(config.containerPadding)
            .background {
                keyboardBackground
            }
        }
    }

    private func numberRow(config: KeyboardConfiguration) -> some View {
        HStack(spacing: config.spacing) {
            ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], id: \.self) { digit in
                KeyboardButton(
                    text: digit,
                    style: .digit,
                    config: config,
                    action: {
                        if let value = Int(digit) {
                            DispatchQueue.main.async {
                                onDigit(value)
                            }
                        }
                    }
                )
            }
        }
        .frame(height: config.digitKeyHeight)
    }

    private func plusRow(config: KeyboardConfiguration) -> some View {
        HStack(spacing: config.spacing) {
            KeyboardButton(text: "+20", style: .increment, config: config) { DispatchQueue.main.async { onPlus20() } }
            KeyboardButton(text: "+50", style: .increment, config: config) { DispatchQueue.main.async { onPlus50() } }
            KeyboardButton(text: "+100", style: .increment, config: config) { DispatchQueue.main.async { onPlus100() } }
            KeyboardButton(text: "+150", style: .increment, config: config) {
                DispatchQueue.main.async {
                    onPlus100()
                    onPlus50()
                }
            }
        }
        .frame(height: config.keyHeight)
    }

    private func minusRow(config: KeyboardConfiguration) -> some View {
        HStack(spacing: config.spacing) {
            KeyboardButton(text: "−20", style: .decrement, config: config) { DispatchQueue.main.async { onMinus20() } }
            KeyboardButton(text: "−50", style: .decrement, config: config) { DispatchQueue.main.async { onMinus50() } }
            KeyboardButton(text: "−100", style: .decrement, config: config) { DispatchQueue.main.async { onMinus100() } }
            KeyboardButton(text: "−150", style: .decrement, config: config) {
                DispatchQueue.main.async {
                    onMinus100()
                    onMinus50()
                }
            }
        }
        .frame(height: config.keyHeight)
    }

    private func actionRow(config: KeyboardConfiguration) -> some View {
        HStack(spacing: config.spacing) {
            KeyboardButton(text: "Fertig", style: .control, config: config) { DispatchQueue.main.async { onDone() } }
            KeyboardButton(text: "Rest", style: .special, config: config) { DispatchQueue.main.async { onRest() } }
            KeyboardButton(text: "Match", style: .success, config: config) { DispatchQueue.main.async { onMatch() } }
            KeyboardButton(
                systemImage: "delete.left.fill",
                style: .control,
                config: config,
                accessibilityLabel: "Löschen",
                action: { DispatchQueue.main.async { onDelete() } }
            )
        }
        .frame(height: config.keyHeight)
    }

    private var keyboardBackground: some View {
        ZStack {
            Rectangle()
                .fill(Material.bar)
                .ignoresSafeArea(edges: .all)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.02),
                    Color.clear,
                    Color.black.opacity(0.01)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .all)
        }
    }
}
