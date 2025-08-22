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
        // Fixed size for human held cards - only meld view gets reduced
        return geometry.size.width < 768 ? CGSize(width: 50, height: 75) : CGSize(width: 100, height: 150)
    }
    
    private var aiCardSize: CGSize {
        let hasMelds = !player.meldsDeclared.isEmpty
        let isLandscape = geometry.size.width > geometry.size.height
        
        if hasMelds {
            // Reduce opponent card size when they have melds to make room
            if isLandscape {
                // iPad landscape: wider left-to-right, reduce card width
                return geometry.size.width < 768 ? CGSize(width: 25, height: 37) : CGSize(width: 40, height: 60)
            } else {
                // iPhone portrait: taller top-to-bottom, reduce card height
                return geometry.size.width < 768 ? CGSize(width: 28, height: 35) : CGSize(width: 45, height: 56)
            }
        } else {
            // Normal opponent card sizes
            return geometry.size.width < 768 ? CGSize(width: 30, height: 45) : CGSize(width: 50, height: 75)
        }
    }
    
    // MARK: - Responsive Stacking
    private var humanCardSpacing: CGFloat {
        geometry.size.width < 768 ? -33 : -25  // More overlap on iPhone
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
        let hasMelds = !player.meldsDeclared.isEmpty
        
        if isHorizontal {
            let totalWidth = max(cardWidth, cardWidth + (spacing * (cardCount - 1)))
            // Add extra width when melds are present for better visibility
            let meldAdjustment = hasMelds ? 20.0 : 0.0
            return CGSize(width: totalWidth + meldAdjustment, height: cardHeight)
        } else {
            let totalHeight = max(cardHeight, cardHeight + (spacing * (cardCount - 1)))
            // Add extra height when melds are present for better visibility
            let meldAdjustment = hasMelds ? 25.0 : 0.0
            return CGSize(width: cardWidth, height: totalHeight + meldAdjustment)
        }
    }
    
    var body: some View {
        Group {
            if isHuman {
                // Human player's hand - ALWAYS show actual cards
                // Note: Cards are always visible but interaction is controlled by game logic
                humanPlayerHandView
            } else {
                // AI player - show card backs
                aiPlayerHandView
            }
        }
    }
    
    // MARK: - Human Player Hand View
    
    private var humanPlayerHandView: some View {
        HStack(spacing: humanCardSpacing) {
            ForEach(player.held) { card in
                humanCardView(for: card)
            }
        }
        .frame(width: humanContainerSize.width, height: humanContainerSize.height)
        // Removed light blue border indicator - now using name plate flash instead
        // Draw button moved to permanent location in GameBoardBottomSection
        .animation(.easeInOut(duration: 0.3), value: isCurrentTurn)
    }
    
    // MARK: - Individual Human Card View
    
    private func humanCardView(for card: PlayerCard) -> some View {
        CardView(
            card: card,
            isSelected: viewState.selectedCards.contains(card),
            isPlayable: true, // Human player cards are always playable for visual purposes
            showHint: false,
            isDragTarget: viewState.draggedOverCard?.id == card.id
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
                isDragTarget: false
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
    

    
    /**
     * Handles single tap on a hand card for selection/deselection.
     * 
     * This method now delegates card selection validation to the Game Engine,
     * ensuring consistent rule enforcement across all card interactions.
     * The UI is only responsible for managing selection state.
     * 
     * @param card The card that was tapped
     * 
     * @note This method replaces the previous UI-level card selection validation
     * @note All validation logic is now handled by the Game Engine
     * @note UI is responsible only for selection state management
     */
    private func handleCardTap(_ card: PlayerCard) {
        // Single tap - select/deselect for melding
        if game.canPlayerSelectCardForMeld(game.currentPlayer) {
            if viewState.selectedCards.contains(card) {
                viewState.deselectCard(card)
            } else {
                viewState.selectCard(card)
            }
        }
    }
    
    /**
     * Handles double tap on a hand card for immediate play.
     * 
     * This method now delegates card play validation to the Game Engine,
     * ensuring consistent rule enforcement across all card interactions.
     * The UI is only responsible for managing view state after the action.
     * 
     * @param card The card that was double-tapped
     * 
     * @note This method replaces the previous UI-level card play validation
     * @note All validation logic is now handled by the Game Engine
     * @note UI is responsible only for view state management
     */
    private func handleCardDoubleTap(_ card: PlayerCard) {
        // Double tap - play the card immediately
        if game.canPlayerPlayCardFromHand(player, card: card) {
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
