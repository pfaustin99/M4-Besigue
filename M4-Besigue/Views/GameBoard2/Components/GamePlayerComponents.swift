
import SwiftUI

/// GamePlayerNameView - Standalone view for displaying the player's name, status, and floating score circle
struct GamePlayerNameView: View {
    @ObservedObject var player: Player
    let isCurrentTurn: Bool
    let allPlayers: [Player] // Need all players to determine ranking
    
    // Add explicit state observation to force UI updates
    @State private var currentScore: Int = 0
    
    // Computed properties for ranking and colors
    private var playerRanking: Int {
        let sortedPlayers = allPlayers.sorted { $0.score > $1.score }
        let ranking = sortedPlayers.firstIndex(where: { $0.id == player.id }) ?? 0
        print("🏆 RANKING UPDATE: \(player.name)")
        print("   Current score: \(player.score)")
        print("   Ranking: \(ranking + 1) of \(allPlayers.count)")
        print("   All scores: \(allPlayers.map { "\($0.name): \($0.score)" }.joined(separator: ", "))")
        return ranking
    }
    
    private var scoreCircleColor: Color {
        // Check if all players have score <= 0
        let allScoresZeroOrNegative = allPlayers.allSatisfy { $0.score <= 0 }
        
        if allScoresZeroOrNegative {
            // If all scores are 0 or negative, use black background for all
            return Color.black // Black background for all players when all at 0
        } else {
            // Normal ranking colors
            switch playerRanking {
            case 0: return Color(hex: "F1B517") // Regal Gold - 1st place
            case 1: return Color(hex: "016A16") // Forest Green - 2nd place
            case 2: return Color(hex: "00209F") // Deep Navy Blue - 3rd place
            case 3: return Color(hex: "D21034") // Royal Crimson - 4th place
            default: return Color.black // Default black background
            }
        }
    }
    
    private var isLeading: Bool {
        let leading = playerRanking == 0
        print("👑 LEADING CHECK: \(player.name) - isLeading: \(leading)")
        return leading
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
                
                Text("\(currentScore)")
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
        .onAppear {
            // Initialize current score
            currentScore = player.score
            print("🎭 GamePlayerNameView appeared for \(player.name) with score: \(player.score)")
        }
        .onChange(of: player.score) { _, newScore in
            // Force UI update when score changes
            currentScore = newScore
            print("🔄 Score changed for \(player.name): \(player.score) -> \(newScore)")
        }
        .onChange(of: allPlayers.map { $0.score }) { _, _ in
            // Force UI update when any player's score changes
            print("🔄 Any player score changed - forcing UI refresh for \(player.name)")
        }
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
