import SwiftUI

struct RoundControls: View {
    let onAddRound: () -> Void
    let onRemoveRound: () -> Void
    let onClearSelection: () -> Void

    var body: some View {
        HStack {
            RemoveRoundButton(action: onRemoveRound)
            Spacer()
            AddRoundButton(action: {
                dismissKeyboard()
                onClearSelection()
                onAddRound()
            })
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(.top, 4)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

private struct AddRoundButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                Text("Runde")
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .accessibilityLabel("Neue Runde hinzufügen")
    }
}

private struct RemoveRoundButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "minus.circle")
                Text("Runde")
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .accessibilityLabel("Letzte Runde entfernen")
    }
}