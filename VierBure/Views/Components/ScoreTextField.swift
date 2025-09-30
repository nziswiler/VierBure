import SwiftUI
import UIKit

struct ScoreTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var shouldFocus: Bool
    let isEnabled: Bool
    let onSelect: () -> Void
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

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.textAlignment = .center
        textField.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        textField.borderStyle = .none
        textField.delegate = context.coordinator
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        textField.isUserInteractionEnabled = isEnabled

        context.coordinator.configure(for: textField)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.isUserInteractionEnabled = isEnabled

        if isEnabled && shouldFocus && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
            DispatchQueue.main.async {
                self.shouldFocus = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

extension ScoreTextField {
    final class Coordinator: NSObject, UITextFieldDelegate {
        private let parent: ScoreTextField
        private weak var textField: UITextField?
        private var hostingController: UIHostingController<CustomKeyboard>?

        init(_ parent: ScoreTextField) {
            self.parent = parent
        }

        func configure(for textField: UITextField) {
            self.textField = textField

            let keyboard = CustomKeyboard(
                onDigit: { [weak self] digit in
                    self?.appendDigit(digit)
                },
                onDelete: { [weak self] in
                    self?.deleteDigit()
                },
                onPlus20: parent.onPlus20,
                onPlus50: parent.onPlus50,
                onPlus100: parent.onPlus100,
                onMinus20: parent.onMinus20,
                onMinus50: parent.onMinus50,
                onMinus100: parent.onMinus100,
                onClearBottom: parent.onClearBottom,
                onRest: parent.onRest,
                onMatch: parent.onMatch,
                onDone: { [weak self] in
                    self?.done()
                }
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
            textField.inputView = inputView

            self.hostingController = hostingController
        }

        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onSelect()
        }

        private func appendDigit(_ digit: Int) {
            guard let textField = textField else { return }

            var current = textField.text ?? ""
            if current == "0" {
                current = ""
            }

            if current.count >= GameConstants.maxDigitsPerScore {
                return
            }

            current.append(String(digit))
            textField.text = current
            parent.text = current
        }

        private func deleteDigit() {
            guard let textField = textField else { return }

            var current = textField.text ?? ""
            if !current.isEmpty {
                current.removeLast()
            }
            textField.text = current
            parent.text = current
        }

        private func done() {
            textField?.resignFirstResponder()
            parent.onDone()
        }
    }
}