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
                let isCurrentTurn = index == game.currentPlayerIndex
                PlayerScoreCardView(
                    playerNumber: index + 1,
                    player: player,
                    isCurrentTurn: isCurrentTurn,
                    allPlayers: game.players,
                    scoreFont: scoreFont
                )
                .onAppear {
                    print("🎯 Scoreboard Grid: Player \(index + 1) (\(player.name)) - isCurrentTurn: \(isCurrentTurn), currentPlayerIndex: \(game.currentPlayerIndex)")
                }
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            print("🎯 Scoreboard Grid: Total players: \(game.players.count), Current player index: \(game.currentPlayerIndex)")
        }
        .onChange(of: game.currentPlayerIndex) { _, newIndex in
            print("🔄 Scoreboard Grid: Current player changed to index: \(newIndex)")
        }
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
    @ObservedObject var player: Player  // Make sure we observe the player
    let isCurrentTurn: Bool
    let allPlayers: [Player]
    let scoreFont: Font
    
    // MARK: - Device Detection
    private var isIPad: Bool {
        UIScreen.main.bounds.width >= 768
    }
    
    // MARK: - Computed Properties
    private var playerRanking: Int {
        let sortedPlayers = allPlayers.sorted { $0.score > $1.score }
        let ranking = sortedPlayers.firstIndex(where: { $0.id == player.id }) ?? 0
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
        return playerRanking == 0
    }
    
    // MARK: - Turn Highlighting
    private var namePlateColor: Color {
        isCurrentTurn ? Color(hex: "00209F") : Color.black.opacity(0.7)
    }
    
    private var namePlateBorderColor: Color {
        isCurrentTurn ? Color(hex: "F1B517") : Color(hex: "F1B517").opacity(0.6)
    }
    
    private var namePlateTextColor: Color {
        isCurrentTurn ? .white : .white
    }
    
    // MARK: - Player Display Name
    private var displayName: String {
        let defaultName = "Player \(playerNumber)"
        // If the player's name is different from the default "Player #", use the real name
        return player.name != defaultName ? player.name : defaultName
    }
    
    // MARK: - Flexible Circle Sizing
    private var circleSize: CGSize {
        let digitCount = String(player.score).count
        let baseHeight: CGFloat = isIPad ? 32 : 28
        let baseWidth: CGFloat = isIPad ? 32 : 28
        
        // Calculate width needed for digits + padding
        let digitWidth: CGFloat = isIPad ? 14 : 12 // Approximate width per digit
        let padding: CGFloat = isIPad ? 16 : 14
        let requiredWidth = CGFloat(digitCount) * digitWidth + padding
        
        return CGSize(
            width: max(requiredWidth, baseWidth),
            height: baseHeight
        )
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Player name and number
            Text("\(displayName):")
                .font(scoreFont)
                .foregroundColor(namePlateTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Score circle
            ZStack {
                RoundedRectangle(cornerRadius: circleSize.height / 2)
                    .fill(scoreCircleColor)
                    .frame(width: circleSize.width, height: circleSize.height)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("\(player.score)")
                    .font(scoreFont)
                    .fontWeight(.bold)
                    .foregroundColor(scoreCircleColor == Color(hex: "F1B517") ? .black : .white)
            }
            .scaleEffect(isLeading ? 1.1 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: circleSize.height / 2)
                    .stroke(isLeading ? Color(hex: "F1B517") : Color.clear, lineWidth: 2)
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(namePlateColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(namePlateBorderColor, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.3), value: scoreCircleColor)
        .animation(.easeInOut(duration: 0.3), value: isLeading)
        .animation(.easeInOut(duration: 0.3), value: isCurrentTurn)
        .onAppear {
            print("🎯 Scoreboard: \(displayName) score: \(player.score)")
            print("🎯 Scoreboard: \(displayName) isCurrentTurn: \(isCurrentTurn), namePlateColor: \(namePlateColor), namePlateBorderColor: \(namePlateBorderColor)")
            print("🎯 Scoreboard: \(displayName) playerRanking: \(playerRanking), scoreCircleColor: \(scoreCircleColor)")
        }
        .onChange(of: player.score) { _, newScore in
            print("🔄 Scoreboard: \(displayName) score changed to: \(newScore)")
        }
        .onChange(of: isCurrentTurn) { _, newTurn in
            print("🔄 Scoreboard: \(displayName) turn changed to: \(newTurn)")
        }
    }
} 
