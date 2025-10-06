import SwiftUI

struct KeyboardButton: View {
    private let text: String?
    private let systemImage: String?
    private let style: KeyboardButtonStyle
    private let config: KeyboardConfiguration
    private let accessibilityLabel: String?
    private let action: () -> Void

    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)

    init(
        text: String,
        style: KeyboardButtonStyle,
        config: KeyboardConfiguration,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.systemImage = nil
        self.style = style
        self.config = config
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    init(
        systemImage: String,
        style: KeyboardButtonStyle,
        config: KeyboardConfiguration,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.text = nil
        self.systemImage = systemImage
        self.style = style
        self.config = config
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: {
            provideHapticFeedback()
            action()
        }) {
            ZStack {
                buttonBackground

                if let text = text {
                    Text(text)
                        .font(style == .digit ? config.digitFont : config.keyFont)
                        .monospacedDigit()
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .shadow(color: .black.opacity(0.05), radius: 0.5, x: 0, y: 0.5)
                } else if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(config.keyFont.weight(.medium))
                        .foregroundStyle(textColor)
                        .shadow(color: .black.opacity(0.05), radius: 0.5, x: 0, y: 0.5)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel ?? text ?? "")
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous)
            .fill(backgroundMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(
                color: shadowColor,
                radius: 1.5,
                x: 0,
                y: 0.5
            )
    }

    private var backgroundMaterial: some ShapeStyle {
        switch style {
        case .digit:
            return AnyShapeStyle(Material.regular)
        case .increment:
            return AnyShapeStyle(Color(.systemRed).opacity(0.12))
        case .decrement:
            return AnyShapeStyle(Color(.systemGreen).opacity(0.12))
        case .special:
            return AnyShapeStyle(Color(.systemOrange).opacity(0.12))
        case .success:
            return AnyShapeStyle(Color(.systemBlue).opacity(0.12))
        case .control:
            return AnyShapeStyle(Material.thick)
        }
    }

    private var keyCornerRadius: CGFloat {
        style == .digit ? 6 : config.cornerRadius
    }

    private var textColor: Color {
        switch style {
        case .digit, .control:
            return .primary
        case .increment:
            return Color(.systemRed)
        case .decrement:
            return Color(.systemGreen)
        case .special:
            return Color(.systemOrange)
        case .success:
            return Color(.systemBlue)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .digit, .control:
            return Color.black.opacity(0.08)
        case .increment:
            return Color(.systemRed).opacity(0.15)
        case .decrement:
            return Color(.systemGreen).opacity(0.15)
        case .special:
            return Color(.systemOrange).opacity(0.15)
        case .success:
            return Color(.systemBlue).opacity(0.15)
        }
    }

    private func provideHapticFeedback() {
        switch style {
        case .digit:
            Self.lightGenerator.impactOccurred()
        case .special, .success:
            Self.mediumGenerator.impactOccurred()
        default:
            Self.lightGenerator.impactOccurred()
        }
    }
}

enum KeyboardButtonStyle {
    case digit
    case increment
    case decrement
    case special
    case success
    case control
}
