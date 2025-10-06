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
                guard let selected = newValue else { return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(selected.round, anchor: .center)
                    }
                }
            }
            .onChange(of: viewModel.rounds) { oldValue, newValue in
                if newValue > oldValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.35)) {
                            proxy.scrollTo("controls", anchor: .bottom)
                        }
                    }
                }
                else if newValue < oldValue && newValue > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.35)) {
                            proxy.scrollTo("controls", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}
