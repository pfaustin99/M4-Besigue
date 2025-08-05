
import SwiftUI

/// GamePlayerNameView - Standalone view for displaying the player's name and status (now floated by PlayerTable)
struct GamePlayerNameView: View {
    let player: Player
    let isCurrentTurn: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(player.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isCurrentTurn ? .white : .secondary)

            if isCurrentTurn {
                Image(systemName: "person.fill")
                    .foregroundColor(.yellow)
                    .font(.caption2)
            }

            if player.type == .ai {
                Image(systemName: "cpu")
                    .foregroundColor(.blue)
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isCurrentTurn ? Color.blue.opacity(0.3) : Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}

/// GameOtherPlayerHandView - Card backs for AI players (still used by GamePlayerHandView internally)
struct GameOtherPlayerHandView: View {
    let player: Player
    let isHorizontal: Bool
    let angle: Double

    var body: some View {
        HStack(spacing: 6) {
            ForEach(player.held) { _ in
                Image("card_back")
                    .resizable()
                    .frame(width: 40, height: 60)
                    .rotationEffect(.degrees(angle))
            }
        }
        .frame(width: isHorizontal ? 180 : 60, height: isHorizontal ? 60 : 180)
    }
}
