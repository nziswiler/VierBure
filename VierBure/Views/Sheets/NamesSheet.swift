import SwiftUI

struct NamesSheet: View {
    @ObservedObject var viewModel: ScoreboardViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Int?

    private let allPlayerNames: Binding<[String]>

    init(viewModel: ScoreboardViewModel) {
        self.viewModel = viewModel
        self.allPlayerNames = Binding(
            get: { viewModel.allPlayerNames },
            set: { newNames in
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(0..<GameConstants.maxPlayers, id: \.self) { index in
                        playerNameRow(for: index)
                    }
                } footer: {
                    footerView
                }
            }
            .navigationTitle("Namen bearbeiten")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        focusedField = nil
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                    }
                    .tint(.secondary)
                    .accessibilityLabel("Abbrechen")
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        applyDefaultNamesForEmptyFields()
                        focusedField = nil
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .imageScale(.large)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .tint(.blue)
                    .accessibilityLabel("Fertig")
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") {
                        focusedField = nil
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(focusedField != nil)
    }

    private func playerNameRow(for index: Int) -> some View {
        HStack(spacing: 12) {
            playerIndicator(for: index)
            playerNameTextField(for: index)
        }
        .padding(.vertical, 4)
    }

    private func playerIndicator(for index: Int) -> some View {
        Text("\(index + 1)")
            .font(.body.weight(.semibold))
            .foregroundStyle(
                index < viewModel.players.count ? .white : .secondary
            )
            .frame(width: 32, height: 32)
            .background {
                Circle()
                    .fill(
                        index < viewModel.players.count ?
                        AnyShapeStyle(Color.accentColor) :
                        AnyShapeStyle(Material.ultraThin)
                    )
                    .shadow(
                        color: index < viewModel.players.count ?
                        Color.accentColor.opacity(0.3) :
                        Color.clear,
                        radius: 2,
                        x: 0,
                        y: 1
                    )
            }
    }

    private func playerNameTextField(for index: Int) -> some View {
        TextField("Spieler \(index + 1)", text: nameBinding(for: index))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .focused($focusedField, equals: index)
            .submitLabel(.next)
            .onSubmit {
                if index < GameConstants.maxPlayers - 1 {
                    focusedField = index + 1
                } else {
                    focusedField = nil
                }
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
    }

    private func nameBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard viewModel.allPlayerNames.indices.contains(index) else {
                    return GameConstants.defaultPlayerNames[index]
                }
                return viewModel.allPlayerNames[index]
            },
            set: { newValue in
                let limited = String(newValue.prefix(10))
                viewModel.updatePlayerName(limited, at: index)
            }
        )
    }

    private var footerView: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.secondary)
            Text("\(viewModel.players.count) von \(GameConstants.maxPlayers) Spielern aktiv")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func applyDefaultNamesForEmptyFields() {
        for index in 0..<GameConstants.maxPlayers {
            if viewModel.allPlayerNames.indices.contains(index) {
                let trimmed = viewModel.allPlayerNames[index]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    viewModel.updatePlayerName(
                        GameConstants.defaultPlayerNames[index],
                        at: index
                    )
                }
            }
        }
    }
}

