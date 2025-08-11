import SwiftUI

/// GameBoardTopSection - Top section containing scoreboard and controls
struct GameBoardTopSection: View {
    let game: Game
    let settings: GameSettings
    let viewState: GameBoardViewState2
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: geometry.size.width > geometry.size.height ? 2 : 4) {
            // Scoreboard
            GameScoreboardView2(game: game, settings: settings)
                .padding(.horizontal)
            
            // Draw pile count label
            DrawPileCountLabel(game: game, geometry: geometry)
            
            // Game status message
            if let message = getGameStatusMessage() {
                GameStatusMessageView(message: message)
            }
        }
        .padding(.top, 2) // Minimal top padding to keep header at top
    }
    
    private func getGameStatusMessage() -> String? {
        if game.isShowingTrickResult, let winnerName = game.lastTrickWinner {
            return "\(winnerName) wins the trick!"
        } else if game.currentPhase == .playing {
            return "\(game.currentPlayer.name)'s Turn"
        }
        return nil
    }
}

/// DrawPileCountLabel - Shows draw pile count with blue background
struct DrawPileCountLabel: View {
    let game: Game
    let geometry: GeometryProxy
    
    // MARK: - Device Detection
    private var isIPad: Bool {
        let maxDimension = max(geometry.size.width, geometry.size.height)
        return maxDimension >= 1024
    }
    
    // MARK: - Computed Properties
    private var remainingCount: Int {
        game.deck.remainingCount
    }
    
    private var playerCount: Int {
        game.players.count
    }
    
    private var roundsRemaining: Int {
        playerCount > 0 ? remainingCount / playerCount : 0
    }
    
    private var shouldShowRedText: Bool {
        roundsRemaining <= 5
    }
    
    var body: some View {
        HStack {
            Text("Draw Pile: \(remainingCount)")
                .font(getDrawPileCountFont(for: isIPad))
                .foregroundColor(shouldShowRedText ? .red : .white)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "00209F"))
                .cornerRadius(8)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Responsive Font
    private func getDrawPileCountFont(for isIPad: Bool) -> Font {
        if isIPad {
            return .system(size: 14, weight: .bold)
        } else {
            return .system(size: 12, weight: .bold)
        }
    }
}

/// GameStatusMessageView - Displays game status messages
struct GameStatusMessageView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
    }
} 