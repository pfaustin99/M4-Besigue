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
    
    /**
     * Determines if the meld button should be shown for the current player.
     * 
     * This computed property now delegates to the Game Engine for all rule validation,
     * ensuring consistent meld button visibility logic across the application.
     * 
     * @return Bool indicating if the meld button should be visible
     * 
     * @note This property replaces the previous UI-level rule enforcement
     * @note All validation logic is now handled by the Game Engine
     * @note UI is responsible only for display, not rule enforcement
     */
    private var shouldShowMeldButton: Bool {
        guard let human = game.players.first(where: { $0.type == .human }) else { return false }
        return game.shouldShowMeldButton(for: human, selectedCards: viewState.selectedCards)
    }
    
    /**
     * Handles meld declaration from UI interaction.
     * 
     * This method now delegates all meld validation and processing to the Game Engine,
     * ensuring consistent rule enforcement and proper error handling. The UI is only
     * responsible for displaying the results and managing view state.
     * 
     * @note This method replaces the previous UI-level meld declaration logic
     * @note All validation and processing is now handled by the Game Engine
     * @note UI is responsible only for user interaction and display feedback
     */
    private func handleMeldDeclaration() {
        guard let humanPlayer = game.players.first(where: { $0.type == .human }) else { return }
        
        // Delegate all meld validation and processing to the Game Engine
        let result = game.declareMeldFromUI(player: humanPlayer, selectedCards: viewState.selectedCards)
        
        if result.success {
            // Meld declared successfully - clear selection and continue
            viewState.clearSelectedCards()
        } else {
            // Meld declaration failed - show error feedback
            viewState.triggerMeldButtonShake()
            viewState.showInvalidMeldMessage()
            
            // Log the failure reason for debugging
            print("❌ Meld declaration failed: \(result.reason)")
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
    
    /**
     * Handles single tap on a melded card for selection/deselection.
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
        if game.canPlayerSelectCardForMeld(game.currentPlayer) {
            if viewState.selectedCards.contains(card) {
                viewState.deselectCard(card)
            } else {
                viewState.selectCard(card)
            }
        }
    }
    
    /**
     * Handles double tap on a melded card for immediate play.
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
        if game.canPlayerPlayCardFromHand(player, card: card) {
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
    
    /**
     * Determines if the draw button should be enabled for the current player.
     * 
     * This computed property now delegates to the Game Engine for all rule validation,
     * ensuring consistent drawing logic across the application. The UI is only
     * responsible for displaying the button state, not enforcing game rules.
     * 
     * @return Bool indicating if the draw button should be enabled
     * 
     * @note This property replaces the previous UI-level rule enforcement
     * @note All validation logic is now handled by the Game Engine
     * @note UI is responsible only for display, not rule enforcement
     */
    private var canDraw: Bool {
        // Get the human player, not the current player (which might be AI)
        guard let humanPlayer = game.players.first(where: { $0.type == .human }) else { return false }
        return game.canPlayerDraw(humanPlayer)
    }
    
    /**
     * Determines if the meld button should be enabled for the current player.
     * 
     * This computed property now delegates to the Game Engine for all rule validation,
     * ensuring consistent melding logic across the application. The UI is only
     * responsible for displaying the button state, not enforcing game rules.
     * 
     * @return Bool indicating if the meld button should be enabled
     * 
     * @note This property replaces the previous UI-level rule enforcement
     * @note All validation logic is now handled by the Game Engine
     * @note UI is responsible only for display, not rule enforcement
     */
    private var canMeld: Bool {
        guard let human = game.players.first(where: { $0.type == .human }) else { return false }
        return game.canPlayerMeld(human, selectedCards: viewState.selectedCards)
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
    
    /**
     * Handles meld declaration from the permanent meld button.
     * 
     * This method now delegates all meld validation and processing to the Game Engine,
     * ensuring consistent rule enforcement and proper error handling. The UI is only
     * responsible for displaying the results and managing view state.
     * 
     * @note This method replaces the previous UI-level meld declaration logic
     * @note All validation and processing is now handled by the Game Engine
     * @note UI is responsible only for user interaction and display feedback
     */
    private func handleMeldDeclaration() {
        guard let humanPlayer = game.players.first(where: { $0.type == .human }) else { return }
        
        // Delegate all meld validation and processing to the Game Engine
        let result = game.declareMeldFromUI(player: humanPlayer, selectedCards: viewState.selectedCards)
        
        if result.success {
            // Meld declared successfully - clear selection and continue
            viewState.clearSelectedCards()
        } else {
            // Meld declaration failed - show error feedback
            viewState.triggerMeldButtonShake()
            viewState.showInvalidMeldMessage()
            
            // Log the failure reason for debugging
            print("❌ Meld declaration failed: \(result.reason)")
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
