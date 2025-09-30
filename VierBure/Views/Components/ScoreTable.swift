import SwiftUI

struct ScoreTable: View {
    @ObservedObject var viewModel: ScoreboardViewModel
    let onError: (String) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(0..<viewModel.rounds, id: \.self) { round in
                    ScoreRow(
                        round: round,
                        viewModel: viewModel,
                        onError: onError
                    )
                }

                RoundControls(
                    onAddRound: viewModel.addRound,
                    onRemoveRound: viewModel.removeLastRound,
                    onClearSelection: viewModel.clearSelection
                )

                Spacer(minLength: 10)
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