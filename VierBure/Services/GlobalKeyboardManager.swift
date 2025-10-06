import SwiftUI
import UIKit

class GlobalKeyboardManager: ObservableObject {
    static let shared = GlobalKeyboardManager()

    private init() {}

    func getKeyboardInputView(
        onDigit: @escaping (Int) -> Void,
        onDelete: @escaping () -> Void,
        onPlus20: @escaping () -> Void,
        onPlus50: @escaping () -> Void,
        onPlus100: @escaping () -> Void,
        onMinus20: @escaping () -> Void,
        onMinus50: @escaping () -> Void,
        onMinus100: @escaping () -> Void,
        onClearBottom: @escaping () -> Void,
        onRest: @escaping () -> Void,
        onMatch: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) -> UIInputView {
        // Berechne Dimensionen basierend auf dem aktuellen Screen
        let width = UIScreen.main.bounds.width
        let config = KeyboardConfiguration(width: width)
        let totalHeight = config.calculateTotalHeight()
        
        // Erstelle CustomKeyboard View
        let keyboard = CustomKeyboard(
            onDigit: onDigit,
            onDelete: onDelete,
            onPlus20: onPlus20,
            onPlus50: onPlus50,
            onPlus100: onPlus100,
            onMinus20: onMinus20,
            onMinus50: onMinus50,
            onMinus100: onMinus100,
            onClearBottom: onClearBottom,
            onRest: onRest,
            onMatch: onMatch,
            onDone: onDone
        )

        // Erstelle HostingController für SwiftUI View
        let hostingController = UIHostingController(rootView: keyboard)
        hostingController.view.backgroundColor = .clear
        
        // Erstelle UIInputView mit fester Größe
        let inputView = UIInputView(
            frame: CGRect(x: 0, y: 0, width: width, height: totalHeight),
            inputViewStyle: .keyboard
        )
        
        // Konfiguriere InputView Properties
        inputView.allowsSelfSizing = false
        inputView.translatesAutoresizingMaskIntoConstraints = true
        
        // Konfiguriere HostingController View
        hostingController.view.frame = inputView.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.view.translatesAutoresizingMaskIntoConstraints = true

        // Füge HostingController View zur InputView hinzu
        inputView.addSubview(hostingController.view)

        return inputView
    }
}
