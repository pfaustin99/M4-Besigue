import SwiftUI

/// GameBoardCenterSection - Center section containing the main game area
struct GameBoardCenterSection: View {
    let game: Game
    let settings: GameSettings
    let gameRules: GameRules
    let viewState: GameBoardViewState2
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            // Game table background
            GameTableBackgroundView()
            
            // Players arranged in a circle
            GamePlayersCircleView(
                game: game,
                settings: settings,
                viewState: viewState,
                geometry: geometry
            )
            
            // Trick area in center
            GameTrickAreaView(
                game: game,
                settings: settings,
                gameRules: gameRules
            )
            
            // Floating draw pile - REMOVED: replaced with DrawPileLayerView in bottom section
            // FloatingDrawPileView(game: game)
        }
    }
}

/// GameTableBackgroundView - Background for the game table
struct GameTableBackgroundView: View {
    var body: some View {
        Color.clear
    }
}

/// GameTrickAreaView - Displays the current trick
struct GameTrickAreaView: View {
    let game: Game
    let settings: GameSettings
    let gameRules: GameRules
    
    var body: some View {
        Group {
            if game.currentTrick.isEmpty {
                // Empty trick area
                VStack(spacing: 4) {
                    Text("TRICK AREA")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(GameBoardConstants.Colors.primaryGreen)
                    Text("Cards played here")
                        .font(.caption2)
                        .foregroundColor(GameBoardConstants.Colors.primaryGreen)
                }
                .frame(width: 100)
                .fixedSize()
            } else {
                // Show actual trick cards
                TrickView(
                    cards: game.currentTrick,
                    game: game,
                    settings: settings,
                    gameRules: gameRules
                )
                .frame(width: 200, height: 120)
            }
        }
    }
}

/// GameDrawPileView - Displays the draw pile
struct GameDrawPileView: View {
    let game: Game
    
    var body: some View {
        VStack(spacing: 4) {
            // Draw pile cards
            ZStack {
                ForEach(0..<min(3, game.deck.cards.count), id: \.self) { index in
                    CardBackView { }
                        .frame(width: 40, height: 60)
                        .offset(x: CGFloat(index) * 2, y: CGFloat(index) * 2)
                }
            }
            
            Text("\(game.deck.cards.count)")
                .font(.caption2)
                .foregroundColor(.white)
        }
        .position(x: 100, y: 100) // Position in top-left area
    }
} 
