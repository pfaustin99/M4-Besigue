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
            
            // Permanent Draw and Meld buttons below human hand
            HumanActionButtonsView(
                game: game,
                viewState: viewState,
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
    
    private var shouldShowMeldButton: Bool {
        guard let human = game.players.first(where: { $0.type == .human }) else { return false }
        return game.awaitingMeldChoice &&
               game.canPlayerMeld &&
               viewState.selectedCards.count >= 2 &&
               viewState.selectedCards.count <= 4 &&
               game.trickWinnerId == human.id
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
                                isDragTarget: viewState.draggedOverCard?.id == card.id,
                                onTap: { handleCardTap(card) },
                                onDoubleTap: { handleCardDoubleTap(card) },
                                settings: settings
                            )
                            .onDrag {
                                // Track drag start
                                viewState.setDragging(true)
                                // Create drag item with card ID for reordering
                                return NSItemProvider(object: card.id.uuidString as NSString)
                            } preview: {
                                // Show a preview of the card being dragged
                                GameMeldedCardView(
                                    card: card,
                                    isSelected: false,
                                    isPlayable: false,
                                    isDragTarget: false,
                                    onTap: {},
                                    onDoubleTap: {},
                                    settings: settings
                                )
                                .scaleEffect(0.8)
                                .opacity(0.8)
                            }
                            .onDrop(of: [.text], delegate: EnhancedCardDropDelegate(
                                card: card,
                                cards: meldedCards,
                                onReorder: { newOrder in
                                    handleMeldedCardsReorder(newOrder)
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
    
    private func handleMeldedCardsReorder(_ newOrder: [PlayerCard]) {
        // Update the melded cards order in the data model
        let newOrderIds = newOrder.map { $0.id }
        player.updateMeldedOrder(newOrderIds)
        print("🔄 Melded cards reordered: \(newOrder.map { $0.displayName })")
    }
}

/// HumanActionButtonsView - Permanent Draw and Meld buttons for human player
struct HumanActionButtonsView: View {
    let game: Game
    let viewState: GameBoardViewState2
    let geometry: GeometryProxy
    
    // MARK: - Responsive Sizing
    private var buttonSpacing: CGFloat {
        geometry.size.width < 768 ? 20 : 30
    }
    
    private var iconSize: CGFloat {
        geometry.size.width < 768 ? 18 : 22
    }
    
    private var textSize: CGFloat {
        geometry.size.width < 768 ? 14 : 16
    }
    
    private var buttonPadding: CGFloat {
        geometry.size.width < 768 ? 12 : 16
    }
    
    var body: some View {
        // UI rule:
        // - While a meld decision is pending (awaitingMeldChoice == true), enable Meld and disable Draw.
        // - After meld resolution (awaitingMeldChoice == false), enable Draw for the player at currentDrawIndex.
        HStack(spacing: buttonSpacing) {
            // Draw Button
            Button(action: {
                game.drawCardForCurrentPlayer()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: iconSize))
                    Text("Draw")
                        .font(.system(size: textSize, weight: .bold))
                }
                .padding(.horizontal, buttonPadding)
                .padding(.vertical, buttonPadding)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(drawButtonColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(drawButtonBorderColor, lineWidth: 2)
                )
            }
            .disabled(!canDraw)
            .foregroundColor(drawButtonTextColor)
            
            // Declare Meld Button
            Button(action: {
                handleMeldDeclaration()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: iconSize))
                    Text("Meld")
                        .font(.system(size: textSize, weight: .bold))
                }
                .padding(.horizontal, buttonPadding)
                .padding(.vertical, buttonPadding)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(meldButtonColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(meldButtonBorderColor, lineWidth: 2)
                )
            }
            .disabled(!canMeld)
            .foregroundColor(meldButtonTextColor)
        }
       // .padding(.top, 20)
    }
    
    // MARK: - Button States
    
    private var canDraw: Bool {
        // Only the current player may draw, and only if they are the human
        let current = game.currentPlayer
        guard current.type == .human,
              let playerIndex = game.players.firstIndex(where: { $0.id == current.id }) else {
            return false
        }

        // Block drawing while a meld decision is pending
        guard !game.awaitingMeldChoice else { return false }

        // Enforce draw order and per-player draw gating
        let hasAlreadyDrawn = game.hasDrawnForNextTrick[current.id, default: false]
        return playerIndex == game.currentDrawIndex &&
               !hasAlreadyDrawn &&
               !game.deck.isEmpty &&
               current.hand.count < 9
    }
    
    private var canMeld: Bool {
        guard let human = game.players.first(where: { $0.type == .human }) else { return false }
        return game.awaitingMeldChoice &&
               game.canPlayerMeld &&
               viewState.selectedCards.count >= 2 &&
               viewState.selectedCards.count <= 4 &&
               game.trickWinnerId == human.id
    }
    
    // MARK: - Button Colors
    
    private var drawButtonColor: Color {
        canDraw ? Color(hex: "00209F") : Color.gray.opacity(0.3)
    }
    
    private var drawButtonBorderColor: Color {
        canDraw ? Color(hex: "F1B517") : Color.gray.opacity(0.5)
    }
    
    private var drawButtonTextColor: Color {
        canDraw ? .white : .gray
    }
    
    private var meldButtonColor: Color {
        canMeld ? Color.green : Color.gray.opacity(0.3)
    }
    
    private var meldButtonBorderColor: Color {
        canMeld ? Color(hex: "F1B517") : Color.gray.opacity(0.5)
    }
    
    private var meldButtonTextColor: Color {
        canMeld ? .white : .gray
    }
    
    // MARK: - Meld Declaration
    
    private func handleMeldDeclaration() {
        guard let humanPlayer = game.players.first(where: { $0.type == .human }),
              viewState.selectedCards.count >= 2,
              viewState.selectedCards.count <= 4 else {
            return
        }
        
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

// MARK: - Melded Card Drop Delegate for Drag and Drop
struct MeldedCardDropDelegate: DropDelegate {
    let card: PlayerCard
    let cards: [PlayerCard]
    let onReorder: ([PlayerCard]) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        // Get the dragged card ID
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        
        itemProvider.loadObject(ofClass: NSString.self) { string, _ in
            guard let cardIdString = string as? String,
                  let draggedCardId = UUID(uuidString: cardIdString),
                  let draggedCard = cards.first(where: { $0.id == draggedCardId }),
                  let draggedIndex = cards.firstIndex(where: { $0.id == draggedCardId }),
                  let dropIndex = cards.firstIndex(where: { $0.id == card.id }) else { return }
            
            // Don't reorder if dropping on the same card
            guard draggedIndex != dropIndex else { return }
            
            DispatchQueue.main.async {
                // Create new order by moving the dragged card to the drop position
                var newOrder = cards
                newOrder.remove(at: draggedIndex)
                newOrder.insert(draggedCard, at: dropIndex)
                
                // Call the reorder callback
                onReorder(newOrder)
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Visual feedback when dragging over a drop target
    }
    
    func dropExited(info: DropInfo) {
        // Clear visual feedback when leaving drop target
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Allow the drop
        return DropProposal(operation: .move)
    }
}

/// GameMeldedCardView - Individual melded card view
struct GameMeldedCardView: View {
    let card: PlayerCard
    let isSelected: Bool
    let isPlayable: Bool
    let isDragTarget: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let settings: GameSettings
    
    var body: some View {
        CardView(
            card: card,
            isSelected: isSelected,
            isPlayable: isPlayable,
            isDragTarget: isDragTarget,
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
