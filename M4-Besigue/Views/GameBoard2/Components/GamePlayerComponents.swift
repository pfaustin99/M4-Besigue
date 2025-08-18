
import SwiftUI

/// GamePlayerNameView - Standalone view for displaying the player's name, status, and floating score circle
struct GamePlayerNameView: View {
    @ObservedObject var player: Player
    let isCurrentTurn: Bool
    let allPlayers: [Player] // Need all players to determine ranking
    
    // Add explicit state observation to force UI updates
    @State private var currentScore: Int = 0
    
    // MARK: - Device Detection
    private var isIPad: Bool {
        // Use a reasonable threshold for iPad detection
        UIScreen.main.bounds.width >= 768
    }
    
    // MARK: - Responsive Font Sizing
    private var playerNameFont: Font {
        isIPad ? .body : .callout
    }
    
    private var scoreFont: Font {
        isIPad ? .body : .callout
    }
    
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
        // Check if all players have score <= 0 (except dog/last place)
        let allScoresZeroOrNegative = allPlayers.allSatisfy { $0.score <= 0 }
        
        if allScoresZeroOrNegative {
            // If all scores are 0 or negative, use black background for all
            return Color.black
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
    
    // MARK: - Active Turn Styling (like Draw button)
    private var namePlateColor: Color {
        isCurrentTurn ? Color(hex: "00209F") : Color.white
    }
    
    private var namePlateBorderColor: Color {
        isCurrentTurn ? Color(hex: "F1B517") : Color(hex: "F1B517")
    }
    
    private var namePlateTextColor: Color {
        isCurrentTurn ? .white : .black
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Player name plate
            HStack(spacing: 4) {
                Text(player.name)
                    .font(playerNameFont)
                    .fontWeight(.semibold)
                    .foregroundColor(namePlateTextColor)
                
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
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(namePlateColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(namePlateBorderColor, lineWidth: 2)
            )
            
            // Floating score circle
            ZStack {
                Circle()
                    .fill(scoreCircleColor)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("\(currentScore)")
                    .font(scoreFont)
                    .fontWeight(.bold)
                    .foregroundColor(scoreCircleColor == Color(hex: "F1B517") ? .black : .white)
            }
            .scaleEffect(isLeading ? 1.1 : 1.0)
            .overlay(
                Circle()
                    .stroke(isLeading ? Color(hex: "F1B517") : Color.clear, lineWidth: 2)
            )
        }
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
            print("🔄 Any player score changed, updating UI for \(player.name)")
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
