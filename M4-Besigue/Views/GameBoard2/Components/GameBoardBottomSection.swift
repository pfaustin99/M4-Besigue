import SwiftUI

/// GameBoardBottomSection - Bottom section for player actions and controls
struct GameBoardBottomSection: View {
    let game: Game
    let settings: GameSettings
    let viewState: GameBoardViewState2
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 8) {
            // Action buttons
            GameActionButtonsView(
                game: game,
                viewState: viewState
            )
            
            // Player melded cards area
            if let currentPlayer = game.players.first(where: { $0.isCurrentPlayer }) {
                GamePlayerMeldedCardsView(
                    player: currentPlayer,
                    game: game,
                    settings: settings,
                    viewState: viewState
                )
            }
            
            // Floating draw button (only when needed)
            if game.mustDrawCard && game.currentPlayer.type == .human {
                FloatingDrawButton(game: game, geometry: geometry)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

/// GameActionButtonsView - Action buttons for the current player
struct GameActionButtonsView: View {
    let game: Game
    let viewState: GameBoardViewState2
    
    var body: some View {
        HStack(spacing: 15) {
            // Play Card button
            if shouldShowPlayButton {
                Button("Play Card") {
                    if let cardToPlay = viewState.selectedCards.first {
                        game.playCard(cardToPlay, from: game.currentPlayer)
                        viewState.clearSelectedCards()
                    }
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
            }
            
            // Declare Meld button
            if shouldShowMeldButton {
                Button("Declare Meld") {
                    handleMeldDeclaration()
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                .scaleEffect(viewState.shakeMeldButton ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: viewState.shakeMeldButton)
            }
        }
    }
    
    private var shouldShowPlayButton: Bool {
        game.currentPhase == .playing &&
        game.currentPlayer.type == .human &&
        !game.awaitingMeldChoice &&
        !viewState.selectedCards.isEmpty &&
        game.canPlayCard()
    }
    
    private var shouldShowMeldButton: Bool {
        game.awaitingMeldChoice &&
        game.currentPlayer.type == .human &&
        game.canPlayerMeld &&
        viewState.selectedCards.count >= 2 &&
        viewState.selectedCards.count <= 4 &&
        game.currentPlayer.id == game.trickWinnerId
    }
    
    private func handleMeldDeclaration() {
        let humanPlayer = game.currentPlayer
        if humanPlayer.type == .human, viewState.selectedCards.count >= 2, viewState.selectedCards.count <= 4 {
            let uniqueSelectedCards = Array(Set(viewState.selectedCards))
            
            if let meldType = game.getMeldTypeForCards(uniqueSelectedCards, trumpSuit: game.trumpSuit) {
                let pointValue = game.getPointValueForMeldType(meldType)
                let meld = Meld(
                    cardIDs: uniqueSelectedCards.map { $0.id },
                    type: meldType,
                    pointValue: pointValue,
                    roundNumber: game.roundNumber
                )
                
                if game.canDeclareMeld(meld, by: humanPlayer) {
                    game.declareMeld(meld, by: humanPlayer)
                    viewState.clearSelectedCards()
                } else {
                    viewState.triggerMeldButtonShake()
                    viewState.showInvalidMeldMessage()
                }
            } else {
                viewState.triggerMeldButtonShake()
                viewState.showInvalidMeldMessage()
            }
        }
    }
}

/// GamePlayerMeldedCardsView - Shows the current player's melded cards
struct GamePlayerMeldedCardsView: View {
    let player: Player
    let game: Game
    let settings: GameSettings
    let viewState: GameBoardViewState2
    
    var body: some View {
        let meldedCards = player.getMeldedCardsInOrder()
        
        if !meldedCards.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Melded Cards")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(meldedCards) { card in
                            GameMeldedCardView(
                                card: card,
                                isSelected: viewState.selectedCards.contains(card),
                                isPlayable: game.getPlayableCards().contains { $0.id == card.id },
                                onTap: { handleCardTap(card) },
                                onDoubleTap: { handleCardDoubleTap(card) },
                                settings: settings
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func handleCardTap(_ card: PlayerCard) {
        if game.awaitingMeldChoice && game.currentPlayer.type == .human && game.canPlayerMeld && game.currentPlayer.id == game.trickWinnerId {
            if viewState.selectedCards.contains(card) {
                viewState.deselectCard(card)
            } else {
                viewState.selectCard(card)
            }
        }
    }
    
    private func handleCardDoubleTap(_ card: PlayerCard) {
        if game.currentPlayer.id == player.id && game.canPlayCard() {
            game.playCard(card, from: player)
            viewState.clearSelectedCards()
        }
    }
}

/// GameMeldedCardView - Individual melded card view
struct GameMeldedCardView: View {
    let card: PlayerCard
    let isSelected: Bool
    let isPlayable: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let settings: GameSettings
    
    var body: some View {
        CardView(
            card: card,
            isSelected: isSelected,
            isPlayable: isPlayable,
            onTap: onTap
        )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .onTapGesture(count: 2) {
                onDoubleTap()
            }
    }
}

/// FloatingDrawButton - Floating draw button that appears when player needs to draw
struct FloatingDrawButton: View {
    let game: Game
    let geometry: GeometryProxy
    
    // MARK: - Device Detection
    private var isIPad: Bool {
        let maxDimension = max(geometry.size.width, geometry.size.height)
        return maxDimension >= 1024
    }
    
    var body: some View {
        Button(action: {
            game.drawCardForCurrentPlayer()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(Color(hex: "F1B517"))
                Text("Draw Card")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
            .font(getDrawButtonFont(for: isIPad))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "00209F"))
            .cornerRadius(12)
            .shadow(radius: 4)
        }
    }
    
    // MARK: - Responsive Font
    private func getDrawButtonFont(for isIPad: Bool) -> Font {
        if isIPad {
            return .system(size: 16, weight: .bold)
        } else {
            return .system(size: 14, weight: .bold)
        }
    }
} 