import SwiftUI

extension View {
    func onPressedChange(_ action: @escaping (Bool) -> Void) -> some View {
        modifier(PressedModifier(onPressedChange: action))
    }

    func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

private struct PressedModifier: ViewModifier {
    @State private var isPressed = false
    let onPressedChange: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onPressedChange(true)
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onPressedChange(false)
                    }
            )
    }
}