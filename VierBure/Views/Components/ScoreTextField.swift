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
        // Update text nur wenn es sich geändert hat
        if uiView.text != text {
            uiView.text = text
        }
        
        // Update enabled state
        let wasEnabled = uiView.isUserInteractionEnabled
        uiView.isUserInteractionEnabled = isEnabled
        
        // Handle focus changes
        if isEnabled && shouldFocus {
            if !uiView.isFirstResponder {
                // Verwende einen RunLoop-basierten Ansatz für besseres Timing
                DispatchQueue.main.async {
                    uiView.becomeFirstResponder()
                }
            }
            // Reset shouldFocus flag
            DispatchQueue.main.async {
                self.shouldFocus = false
            }
        } else if !isEnabled && uiView.isFirstResponder {
            // Resigniere nur wenn das Field disabled wurde
            uiView.resignFirstResponder()
        } else if wasEnabled && !isEnabled && uiView.isFirstResponder {
            // Cleanup wenn disabled wird
            uiView.resignFirstResponder()
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

        init(_ parent: ScoreTextField) {
            self.parent = parent
        }

        func configure(for textField: UITextField) {
            self.textField = textField

            let inputView = GlobalKeyboardManager.shared.getKeyboardInputView(
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

            textField.inputView = inputView
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