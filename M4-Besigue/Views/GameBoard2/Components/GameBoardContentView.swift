import SwiftUI

/// GameBoardContentView - Main content coordinator for the game board
/// 
/// This view handles the layout coordination and delegates to specialized components
struct GameBoardContentView: View {
    // MARK: - Dependencies
    @ObservedObject var game: Game
    let settings: GameSettings
    let gameRules: GameRules
    let viewState: GameBoardViewState2
    let geometry: GeometryProxy
    let onEndGame: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section: Scoreboard and controls
            GameBoardTopSection(
                game: game,
                settings: settings,
                viewState: viewState,
                geometry: geometry
            )
            
            Spacer(minLength: 200)  // Push center section down with minimum 50 points
            
            // Center section: Main game area
            GameBoardCenterSection(
                game: game,
                settings: settings,
                gameRules: gameRules,
                geometry: geometry
            )
            
            Spacer()  // Push center section up from bottom
            
            // Bottom section: Player hand and actions
            GameBoardBottomSection(
                game: game,
                settings: settings,
                viewState: viewState,
                geometry: geometry
            )
        }
        .overlay(
            // Floating action buttons
            GameBoardFloatingButtons(
                game: game,
                viewState: viewState,
                onEndGame: onEndGame
            ),
            alignment: .topTrailing
        )
        .overlay(
            // Card animation overlay
            CardAnimationOverlay(viewState: viewState),
            alignment: .center
        )
        .overlay(
            // Floating message overlay for game messages
            FloatingMessageOverlay(game: game),
            alignment: .top
        )
        .overlay(
            // Player hands layout overlay
            GamePlayersLayoutView(
                game: game,
                settings: settings,
                viewState: viewState,
                geometry: geometry
            )
        )
    }
}

// MARK: - Card Animation Overlay

/// CardAnimationOverlay - Shows animations for card playing and drawing
struct CardAnimationOverlay: View {
    let viewState: GameBoardViewState2
    
    var body: some View {
        ZStack {
            // Card play animation
            if viewState.isPlayingCard, let card = viewState.playedCard {
                CardPlayAnimation(card: card)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
            
            // Card draw animation
            if viewState.isDrawingCard, let card = viewState.drawnCard {
                CardDrawAnimation(card: card)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: viewState.cardAnimationDuration), value: viewState.isPlayingCard)
        .animation(.easeInOut(duration: viewState.cardAnimationDuration), value: viewState.isDrawingCard)
    }
}

/// CardPlayAnimation - Animation for when a card is played
struct CardPlayAnimation: View {
    let card: PlayerCard
    
    var body: some View {
        VStack(spacing: 8) {
            Image(card.imageName)
                .resizable()
                .aspectRatio(2.5/3.5, contentMode: .fit)
                .frame(width: 120, height: 168)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            
            Text("Card Played!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(20)
        }
        .scaleEffect(1.2)
        .shadow(color: .blue.opacity(0.5), radius: 20)
    }
}

/// CardDrawAnimation - Animation for when a card is drawn
struct CardDrawAnimation: View {
    let card: PlayerCard
    
    var body: some View {
        VStack(spacing: 8) {
            Image(card.imageName)
                .resizable()
                .aspectRatio(2.5/3.5, contentMode: .fit)
                .frame(width: 120, height: 168)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            
            Text("Card Drawn!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(20)
        }
        .scaleEffect(1.2)
        .shadow(color: .green.opacity(0.5), radius: 20)
    }
} 

// MARK: - Floating Message Overlay

/// FloatingMessageOverlay - Displays floating game messages
struct FloatingMessageOverlay: View {
    let game: Game
    
    var body: some View {
        if let message = game.userMessage {
            VStack(spacing: 8) {
                Text(message)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue.opacity(0.9))
                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.5), value: message)
        }
    }
}

// MARK: - Preview 
