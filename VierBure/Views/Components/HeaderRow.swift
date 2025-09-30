import SwiftUI

struct HeaderRow: View {
    let players: [Player]

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 20)
                .frame(width: 20)

            HStack(spacing: 6) {
                ForEach(players) { player in
                    PlayerNameHeader(name: player.name)
                }
            }

            Spacer(minLength: 20)
                .frame(width: 20)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Player names header")
    }
}

private struct PlayerNameHeader: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(
                .thinMaterial,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .accessibilityLabel("Player: \(name)")
    }
}
