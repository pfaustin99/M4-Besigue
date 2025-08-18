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
        }
        .padding(.top, 2) // Minimal top padding to keep header at top
    }
} 