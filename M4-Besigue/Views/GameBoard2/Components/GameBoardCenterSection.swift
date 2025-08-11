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
            
            // Players arranged in a square layout
            GamePlayersLayoutView(
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
        .frame(maxHeight: geometry.size.width > geometry.size.height ? 
               geometry.size.height * 0.5 : // iPad: compact vertically
               geometry.size.height * 0.7) // iPhone: use more vertical space
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
        if game.isShowingCompletedTrick && !game.completedTrick.isEmpty {
            // Show completed trick with winning card animation
            CompletedTrickView(
                cards: game.completedTrick,
                winningCardIndex: game.completedTrickWinnerIndex,
                game: game,
                settings: settings,
                gameRules: gameRules
            )
            .frame(width: 200, height: 120)
        } else if !game.currentTrick.isEmpty {
            // Show actual trick cards
            TrickView(
                cards: game.currentTrick,
                game: game,
                settings: settings,
                gameRules: gameRules
            )
            .frame(width: 200, height: 120)
        } else {
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
        }
    }
}

/// CompletedTrickView - Displays the completed trick with winning card animation
struct CompletedTrickView: View {
    let cards: [PlayerCard]
    let winningCardIndex: Int?
    let game: Game
    let settings: GameSettings
    let gameRules: GameRules
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                let isWinningCard = index == winningCardIndex
                
                CardView(
                    card: card,
                    isSelected: false,
                    isPlayable: false,
                    showHint: false,
                    size: CGSize(width: 60, height: 90)
                ) { }
                .offset(y: isWinningCard ? -10 : 0) // Winning card rises to the top
                .animation(.easeInOut(duration: 0.5), value: isWinningCard)
                .overlay(
                    // Highlight winning card
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isWinningCard ? Color.yellow : Color.clear, lineWidth: 2)
                        .opacity(isWinningCard ? 0.8 : 0.0)
                        .animation(.easeInOut(duration: 0.3), value: isWinningCard)
                )
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.1))
        .cornerRadius(8)
    }
}

/// TrickView - Displays the current trick cards
struct TrickView: View {
    let cards: [PlayerCard]
    let game: Game
    let settings: GameSettings
    let gameRules: GameRules
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(cards, id: \.id) { card in
                CardView(
                    card: card,
                    isSelected: false,
                    isPlayable: false,
                    showHint: false,
                    size: CGSize(width: 60, height: 90)
                ) { }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.1))
        .cornerRadius(8)
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
