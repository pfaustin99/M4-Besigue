import SwiftUI

/// GameBoardTopSection - Top section containing scoreboard and controls
struct GameBoardTopSection: View {
    let game: Game
    let settings: GameSettings
    let viewState: GameBoardViewState2
    
    var body: some View {
        VStack(spacing: 8) {
            // Scoreboard
            GameScoreboardView2(game: game, settings: settings)
                .padding(.horizontal)
            
            // Game status message
            if let message = getGameStatusMessage() {
                GameStatusMessageView(message: message)
            }
        }
        .padding(.top, 8)
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