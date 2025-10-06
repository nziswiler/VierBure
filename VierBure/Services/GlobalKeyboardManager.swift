import SwiftUI
import UIKit

class GlobalKeyboardManager: ObservableObject {
    static let shared = GlobalKeyboardManager()

    private var hostingController: UIHostingController<CustomKeyboard>?
    private var inputView: UIInputView?

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

        let hostingController = UIHostingController(rootView: keyboard)
        hostingController.view.backgroundColor = .clear

        let inputView = UIInputView(frame: .zero, inputViewStyle: .keyboard)
        inputView.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        inputView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: inputView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: inputView.bottomAnchor)
        ])

        let width = UIScreen.main.bounds.width
        let config = KeyboardConfiguration(width: width)
        let totalHeight = config.calculateTotalHeight()

        inputView.heightAnchor.constraint(equalToConstant: totalHeight).isActive = true

        self.hostingController = hostingController
        self.inputView = inputView

        return inputView
    }
}
