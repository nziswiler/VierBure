import SwiftUI

struct ScoreTable: View {
    @ObservedObject var viewModel: ScoreboardViewModel
    let onError: (String) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(0..<viewModel.rounds, id: \.self) { round in
                        ScoreRow(
                            round: round,
                            viewModel: viewModel,
                            onError: onError
                        )
                        .id(round)
                    }

                    RoundControls(
                        onAddRound: viewModel.addRound,
                        onRemoveRound: viewModel.removeLastRound,
                        onClearSelection: viewModel.clearSelection
                    )
                    .id("controls")

                    // Platzhalter für Keyboard-Platz
                    Color.clear
                        .frame(height: 300)
                        .id("spacer")
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.players)
                .animation(.easeInOut(duration: 0.3), value: viewModel.rounds)
                .padding(.bottom, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.clearSelection()
                    dismissKeyboard()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.selectedCell) { oldValue, newValue in
                // Scrolle nur wenn eine Zelle ausgewählt wurde (nicht beim Deselektieren)
                guard let selected = newValue else { return }
                
                // Scrolle nur wenn die Zelle außerhalb des sichtbaren Bereichs liegt
                // oder wenn es eine späte Runde ist (ab Runde 4)
                if selected.round >= 4 {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(selected.round, anchor: .center)
                    }
                }
            }
        }
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