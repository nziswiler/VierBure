import SwiftUI

struct PlayerCountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCount: Int
    private let onConfirm: (Int) -> Void

    init(currentCount: Int, onConfirm: @escaping (Int) -> Void) {
        _selectedCount = State(initialValue: currentCount)
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Spieleranzahl")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Picker("Spieler", selection: $selectedCount) {
                    ForEach(GameConstants.minPlayers...GameConstants.maxPlayers, id: \.self) { count in
                        Text("\(count)")
                            .tag(count)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                    }
                    .tint(.secondary)
                    .accessibilityLabel("Abbrechen")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let validatedCount = ScoreValidator.validatePlayerCount(selectedCount)
                        onConfirm(validatedCount)
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
            }
        }
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
    }
}

