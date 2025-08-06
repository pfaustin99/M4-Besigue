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
            
            // Draw pile layer
            DrawPileLayerView(
                game: game,
                geometry: geometry
            )
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

/// DrawPileLayerView - Draw pile information and draw button
struct DrawPileLayerView: View {
    let game: Game
    let geometry: GeometryProxy
    
    // MARK: - Device Detection
    private var deviceType: DeviceType {
        DeviceType.current(geometry: geometry)
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
    
    private var isDrawButtonActive: Bool {
        game.mustDrawCard && game.currentPlayer.type == .human
    }
    
    private var buttonColor: Color {
        isDrawButtonActive ? Color(hex: "00209F") : Color.gray.opacity(0.6)
    }
    
    var body: some View {
        HStack {
            // Draw pile count message
            Text("Draw Pile: \(remainingCount)")
                .font(getDrawPileFont(for: deviceType))
                .foregroundColor(shouldShowRedText ? .red : .white)
                .fontWeight(.bold)
            
            Spacer()
            
            // Draw button
            Button(action: {
                if isDrawButtonActive {
                    game.drawCardForCurrentPlayer()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(Color(hex: "F1B517"))
                    Text("Draw Card")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
                .font(getDrawPileFont(for: deviceType))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(buttonColor)
                .cornerRadius(8)
            }
            .disabled(!isDrawButtonActive)
        }
        .padding(.horizontal, getDrawPileHorizontalPadding(for: deviceType))
        .padding(.vertical, getDrawPileVerticalPadding(for: deviceType))
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
    }
    
    // MARK: - Responsive Sizing Functions
    private func getDrawPileFont(for deviceType: DeviceType) -> Font {
        switch deviceType {
        case .iPad:
            return .system(size: 16, weight: .bold)
        case .iPhonePlus:
            return .system(size: 14, weight: .bold)
        case .iPhoneRegular:
            return .footnote.bold()
        case .iPhoneCompact:
            return .system(size: 11, weight: .bold)
        }
    }
    
    private func getDrawPileHorizontalPadding(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad:
            return 4
        case .iPhonePlus:
            return 3
        case .iPhoneRegular:
            return 2
        case .iPhoneCompact:
            return 2
        }
    }
    
    private func getDrawPileVerticalPadding(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad:
            return 4
        case .iPhonePlus:
            return 3
        case .iPhoneRegular:
            return 2
        case .iPhoneCompact:
            return 2
        }
    }
} 