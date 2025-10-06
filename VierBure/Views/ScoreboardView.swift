import SwiftUI

struct ScoreboardView: View {
    @StateObject private var viewModel = ScoreboardViewModel()
    @State private var showNamesSheet = false
    @State private var showPlayerCountSheet = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HeaderRow(players: viewModel.players)
                    .padding(.horizontal, 8)

                Divider()
                    .padding(.horizontal, 8)

                ScoreTable(
                    viewModel: viewModel,
                    onError: showError
                )
                .padding(.horizontal, 8)
            }
            .navigationTitle("Vier Bure")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .safeAreaInset(edge: .bottom) {
                TotalsRow(
                    totals: viewModel.playerTotals,
                    playerNames: viewModel.players.map(\.name)
                )
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .background(.bar)
            }
        }
        .sheet(isPresented: $showNamesSheet) {
            NamesSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showPlayerCountSheet) {
            PlayerCountSheet(currentCount: viewModel.players.count) { count in
                viewModel.setPlayerCount(count)
            }
        }
        .alert("Fehler", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert(
            "Punkte zurücksetzen?",
            isPresented: $showResetConfirmation,
            actions: {
                Button("Zurücksetzen", role: .destructive) {
                    viewModel.resetGame()
                }
                Button("Abbrechen", role: .cancel) { }
            },
            message: {
                Text("Diese Aktion setzt alle Runden und Punkte zurück.")
            }
        )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu("Menü") {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Punkte zurücksetzen", systemImage: "trash")
                }

                Button {
                    showNamesSheet = true
                } label: {
                    Label("Namen eingeben", systemImage: "pencil")
                }

                Button {
                    showPlayerCountSheet = true
                } label: {
                    Label("Spieleranzahl ändern", systemImage: "person.3")
                }
            }
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}

