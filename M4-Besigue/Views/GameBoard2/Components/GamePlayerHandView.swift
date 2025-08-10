import SwiftUI

/// GamePlayerHandView - Displays a player's hand (human or AI)
struct GamePlayerHandView: View {
    let player: Player
    let isHuman: Bool
    let isCurrentTurn: Bool
    let angle: Double
    let isHorizontal: Bool
    let geometry: GeometryProxy
    let game: Game
    let viewState: GameBoardViewState2
    
    // MARK: - Responsive Card Sizing
    private var humanCardSize: CGSize {
        geometry.size.width < 768 ? CGSize(width: 50, height: 75) : CGSize(width: 100, height: 150)
    }
    
    private var aiCardSize: CGSize {
        geometry.size.width < 768 ? CGSize(width: 30, height: 45) : CGSize(width: 50, height: 75)
    }
    
    // MARK: - Responsive Stacking
    private var humanCardSpacing: CGFloat {
        geometry.size.width < 768 ? -20 : -25  // More overlap on iPhone
    }
    
    private var aiCardSpacing: CGFloat {
        geometry.size.width < 768 ? -35 : -25  // More overlap on iPhone
    }
    
    // MARK: - Responsive Container Frames
    private var humanContainerSize: CGSize {
        let cardWidth = humanCardSize.width
        let cardHeight = humanCardSize.height
        let spacing = humanCardSpacing
        let cardCount = CGFloat(player.held.count)
        
        if isHorizontal {
            let totalWidth = max(cardWidth, cardWidth + (spacing * (cardCount - 1)))
            return CGSize(width: totalWidth, height: cardHeight)
        } else {
            let totalHeight = max(cardHeight, cardHeight + (spacing * (cardCount - 1)))
            return CGSize(width: cardWidth, height: totalHeight)
        }
    }
    
    private var aiContainerSize: CGSize {
        let cardWidth = aiCardSize.width
        let cardHeight = aiCardSize.height
        let spacing = aiCardSpacing
        let cardCount = CGFloat(player.held.count)
        
        if isHorizontal {
            let totalWidth = max(cardWidth, cardWidth + (spacing * (cardCount - 1)))
            return CGSize(width: totalWidth, height: cardHeight)
        } else {
            let totalHeight = max(cardHeight, cardHeight + (spacing * (cardCount - 1)))
            return CGSize(width: cardWidth, height: totalHeight)
        }
    }
    
    var body: some View {
        Group {
            if isHuman && isCurrentTurn {
                // Human player's hand - show actual cards
                humanPlayerHandView
            } else {
                // AI player or non-current human - show card backs
                aiPlayerHandView
            }
        }
    }
    
    // MARK: - Human Player Hand View
    
    private var humanPlayerHandView: some View {
        HStack(spacing: humanCardSpacing) {
            ForEach(player.held) { card in
                CardView(
                    card: card,
                    isSelected: viewState.selectedCards.contains(card),
                    isPlayable: game.canPlayCard() && game.currentPlayer.id == player.id,
                    showHint: false,
                    isDragTarget: viewState.draggedOverCard?.id == card.id,
                    size: humanCardSize
                ) {
                    // Single tap - select/deselect for melding
                    handleCardTap(card)
                }
                .onTapGesture(count: 2) {
                    // Double tap - play the card
                    handleCardDoubleTap(card)
                }
                .onDrag {
                    // Track drag start
                    viewState.setDragging(true)
                    // Create drag item with card ID for reordering
                    return NSItemProvider(object: card.id.uuidString as NSString)
                } preview: {
                    // Show a preview of the card being dragged
                    CardView(
                        card: card,
                        isSelected: false,
                        isPlayable: true,
                        showHint: false,
                        isDragTarget: false,
                        size: humanCardSize
                    ) {
                        // Empty action for preview
                    }
                    .scaleEffect(0.8)
                    .opacity(0.8)
                }
                .onDrop(of: [.text], delegate: EnhancedCardDropDelegate(
                    card: card,
                    cards: player.held,
                    onReorder: { newOrder in
                        handleHandReorder(newOrder)
                    },
                    onDragEnter: { card in
                        viewState.setDraggedOverCard(card)
                    },
                    onDragExit: { _ in
                        viewState.clearDraggedOverCard()
                    },
                    onDragEnd: {
                        viewState.setDragging(false)
                        viewState.clearDraggedOverCard()
                    }
                ))
            }
        }
        .frame(width: humanContainerSize.width, height: humanContainerSize.height)
    }
    
    // MARK: - AI Player Hand View
    
    private var aiPlayerHandView: some View {
        HStack(spacing: aiCardSpacing) {
            ForEach(player.held) { _ in
                Image("card_back")
                    .resizable()
                    .frame(width: aiCardSize.width, height: aiCardSize.height)
            }
        }
        .frame(width: aiContainerSize.width, height: aiContainerSize.height)
    }
    
    // MARK: - Card Interaction Methods
    
    private func handleCardTap(_ card: PlayerCard) {
        // Single tap - select/deselect for melding
        if game.awaitingMeldChoice && 
           game.currentPlayer.type == .human && 
           game.canPlayerMeld && 
           game.currentPlayer.id == game.trickWinnerId {
            
            if viewState.selectedCards.contains(card) {
                viewState.deselectCard(card)
            } else {
                viewState.selectCard(card)
            }
        }
    }
    
    private func handleCardDoubleTap(_ card: PlayerCard) {
        // Double tap - play the card immediately
        if game.currentPlayer.id == player.id && game.canPlayCard() {
            game.playCard(card, from: player)
            viewState.clearSelectedCards()
        }
    }
    
    private func handleHandReorder(_ newOrder: [PlayerCard]) {
        // Update the player's hand order in the data model
        player.updateHeldOrder(newOrder)
        print("🔄 Hand reordered: \(newOrder.map { $0.displayName })")
    }
}

// MARK: - Preview
#if DEBUG
struct GamePlayerHandView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                // Human player hand
                GamePlayerHandView(
                    player: Player(name: "Human", type: .human),
                    isHuman: true,
                    isCurrentTurn: true,
                    angle: 0,
                    isHorizontal: true,
                    geometry: geometry,
                    game: Game(gameRules: GameRules(), isOnline: false),
                    viewState: GameBoardViewState2()
                )
                
                // AI player hand
                GamePlayerHandView(
                    player: Player(name: "AI", type: .ai),
                    isHuman: false,
                    isCurrentTurn: false,
                    angle: 0,
                    isHorizontal: true,
                    geometry: geometry,
                    game: Game(gameRules: GameRules(), isOnline: false),
                    viewState: GameBoardViewState2()
                )
            }
            .padding()
            .background(Color.green)
        }
    }
}
#endif 
