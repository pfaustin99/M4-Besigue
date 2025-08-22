import SwiftUI

/// GameScoreboardView2 - Elegant scoreboard component with BÉSIGUE branding and player scores
struct GameScoreboardView2: View {
    let game: Game
    let settings: GameSettings
    
    var body: some View {
        VStack(spacing: 8) {
            // Elegant BÉSIGUE title with modern styling
            Text("BÉSIGUE")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "F1B517"), // Regal Gold
                            Color(hex: "D21034")  // Royal Crimson
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.8),
                                    Color.black.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "F1B517").opacity(0.6),
                                            Color(hex: "D21034").opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
            
            // Player scores grid
            PlayerScoresGridView(game: game)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

// MARK: - Player Scores Grid View
struct PlayerScoresGridView: View {
    let game: Game
    
    // MARK: - Device Detection
    private var isIPad: Bool {
        UIScreen.main.bounds.width >= 768
    }
    
    // MARK: - Responsive Font
    private var scoreFont: Font {
        isIPad ? .system(size: 14, weight: .semibold) : .system(size: 12, weight: .semibold)
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(Array(game.players.enumerated()), id: \.element.id) { index, player in
                PlayerScoreCardView(
                    playerNumber: index + 1,
                    player: player,
                    scoreFont: scoreFont
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Grid Layout
    private var gridColumns: [GridItem] {
        switch game.players.count {
        case 2:
            // 1x2 grid for 2 players
            return [GridItem(.flexible()), GridItem(.flexible())]
        case 3, 4:
            // 2x2 grid for 3-4 players
            return [GridItem(.flexible()), GridItem(.flexible())]
        default:
            // Fallback to single column
            return [GridItem(.flexible())]
        }
    }
}

// MARK: - Player Score Card View
struct PlayerScoreCardView: View {
    let playerNumber: Int
    let player: Player
    let scoreFont: Font
    
    var body: some View {
        HStack(spacing: 6) {
            Text("Player \(playerNumber)(\(player.name)):")
                .font(scoreFont)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("[\(player.score)]")
                .font(scoreFont)
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "F1B517").opacity(0.6), lineWidth: 1)
        )
    }
}

// PlayerScoreCardView removed - scores now displayed next to player names 
