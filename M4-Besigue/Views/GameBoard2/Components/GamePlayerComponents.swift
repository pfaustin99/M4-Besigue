
import SwiftUI

/// GamePlayerNameView - Standalone view for displaying the player's name, status, and floating score circle
struct GamePlayerNameView: View {
    let player: Player
    let isCurrentTurn: Bool
    let allPlayers: [Player] // Need all players to determine ranking
    
    // Computed properties for ranking and colors
    private var playerRanking: Int {
        let sortedPlayers = allPlayers.sorted { $0.score > $1.score }
        return sortedPlayers.firstIndex(where: { $0.id == player.id }) ?? 0
    }
    
    private var scoreCircleColor: Color {
        switch playerRanking {
        case 0: return Color(hex: "F1B517") // Regal Gold - 1st place
        case 1: return Color(hex: "016A16") // Forest Green - 2nd place
        case 2: return Color(hex: "00209F") // Deep Navy Blue - 3rd place
        case 3: return Color(hex: "D21034") // Royal Crimson - 4th place
        default: return Color.black // Default black background
        }
    }
    
    private var isLeading: Bool {
        return playerRanking == 0
    }

    var body: some View {
        HStack(spacing: 6) {
            // Player name
            Text(player.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isCurrentTurn ? .white : .secondary)
            
            // Floating score circle
            ZStack {
                Circle()
                    .fill(scoreCircleColor)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                
                Text("\(player.score)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isLeading ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isLeading)

            // Current turn indicator
            if isCurrentTurn {
                Image(systemName: "person.fill")
                    .foregroundColor(.yellow)
                    .font(.caption2)
            }

            // AI indicator
            if player.type == .ai {
                Image(systemName: "cpu")
                    .foregroundColor(.blue)
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    isCurrentTurn 
                        ? Color.blue.opacity(0.3) 
                        : Color.black.opacity(0.2)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isLeading ? Color(hex: "F1B517").opacity(0.6) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .animation(.easeInOut(duration: 0.3), value: scoreCircleColor)
        .animation(.easeInOut(duration: 0.3), value: isLeading)
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
