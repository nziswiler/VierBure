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
        let width = UIScreen.main.bounds.width
        let config = KeyboardConfiguration(width: width)
        let totalHeight = config.calculateTotalHeight()
        
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
        
        let inputView = KeyboardInputView(
            frame: CGRect(x: 0, y: 0, width: width, height: totalHeight),
            inputViewStyle: .keyboard,
            hostingController: hostingController
        )
        
        inputView.allowsSelfSizing = false
        inputView.translatesAutoresizingMaskIntoConstraints = true
        
        hostingController.view.frame = inputView.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.view.translatesAutoresizingMaskIntoConstraints = true

        inputView.addSubview(hostingController.view)

        return inputView
    }
}

private final class KeyboardInputView: UIInputView {
    private weak var hostingController: UIHostingController<CustomKeyboard>?
    
    init(frame: CGRect, inputViewStyle: UIInputView.Style, hostingController: UIHostingController<CustomKeyboard>) {
        self.hostingController = hostingController
        super.init(frame: frame, inputViewStyle: inputViewStyle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        subviews.forEach { $0.removeFromSuperview() }
    }
}
