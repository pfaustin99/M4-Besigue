import SwiftUI

/// GameBoardMeldRowView - Displays a player's melds in a horizontal row
struct GameBoardMeldRowView: View {
    let player: Player
    let isHuman: Bool
    let geometry: GeometryProxy
    let game: Game
    let viewState: GameBoardViewState2
    
    var body: some View {
        if !player.meldsDeclared.isEmpty {
            HStack(spacing: 2) {  // Tighter spacing for overlay effect
                ForEach(Array(player.meldsDeclared.enumerated()), id: \.element.id) { index, meld in
                    GameBoardMeldView(
                        meld: meld, 
                        player: player, 
                        isHuman: isHuman, 
                        geometry: geometry,
                        game: game,
                        viewState: viewState,
                        displayedCardUUIDs: getDisplayedCardUUIDs(for: meld, at: index)
                    )
                    .offset(y: -2)  // Slight upward offset for overlay effect
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
    
    /// Get the card UUIDs that should be displayed for this specific meld
    /// This prevents duplication across all melds for the player
    private func getDisplayedCardUUIDs(for meld: Meld, at index: Int) -> [UUID] {
        var allDisplayedUUIDs: Set<UUID> = []
        
        // Collect all UUIDs from previous melds
        for i in 0..<index {
            let previousMeld = player.meldsDeclared[i]
            allDisplayedUUIDs.formUnion(previousMeld.cardIDs)
        }
        
        // For this meld, only show cards that haven't been displayed yet
        return meld.cardIDs.filter { cardId in
            !allDisplayedUUIDs.contains(cardId)
        }
    }
}

/// GameBoardMeldView - Individual meld display
struct GameBoardMeldView: View {
    let meld: Meld
    let player: Player
    let isHuman: Bool
    let geometry: GeometryProxy
    let game: Game
    let viewState: GameBoardViewState2
    let displayedCardUUIDs: [UUID]
    
    private var meldCardSize: CGSize {
        let isLandscape = geometry.size.width > geometry.size.height
        let isIPad = geometry.size.width >= 768
        
        if isIPad {
            // iPad: larger meld cards for better visibility
            return isLandscape ? CGSize(width: 45, height: 67) : CGSize(width: 50, height: 75)
        } else {
            // iPhone: appropriately sized meld cards
            return isLandscape ? CGSize(width: 35, height: 52) : CGSize(width: 40, height: 60)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Meld cards with better visibility and interaction
            HStack(spacing: -3) {  // Reduced overlap for better card visibility
                ForEach(filteredMeldCards, id: \.id) { card in
                    CardView(
                        card: card,
                        isSelected: viewState.selectedCards.contains(card),
                        isPlayable: true,  // Meld cards are playable
                        showHint: false,
                        isDragTarget: viewState.draggedOverCard?.id == card.id
                    ) {
                        // Single tap - select/deselect for additional melding
                        handleCardTap(card)
                    }
                    .frame(width: meldCardSize.width, height: meldCardSize.height)
                    .onTapGesture(count: 2) {
                        // Double tap - play the card
                        handleCardDoubleTap(card)
                    }
                }
            }
            
            // Enhanced meld token
            HStack(spacing: 3) {
                Image(systemName: meldTypeIcon(for: meld.type))
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text("\(meld.pointValue)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.8))
                    )
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.9))
                    .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
            )
        }
    }
    
    // MARK: - Computed Properties
    
    /// Filter meld cards to only show cards that should be displayed for this meld
    private var filteredMeldCards: [PlayerCard] {
        var cards: [PlayerCard] = []
        
        for cardId in displayedCardUUIDs {
            if let card = player.melded.first(where: { $0.id == cardId }) {
                cards.append(card)
            }
        }
        
        return cards
    }
    
    // MARK: - Card Interaction Logic
    
    private func handleCardTap(_ card: PlayerCard) {
        if viewState.selectedCards.contains(card) {
            // Deselect the card
            viewState.deselectCard(card)
        } else {
            // Select the card for additional melding
            viewState.selectCard(card)
        }
    }
    
    private func handleCardDoubleTap(_ card: PlayerCard) {
        if game.canPlayerPlayCardFromHand(player, card: card) {
            game.playCard(card, from: player)
            viewState.clearSelectedCards()
        }
    }
    
    private func meldTypeIcon(for type: MeldType) -> String {
        switch type {
        case .royalMarriage: return "crown.fill"
        case .commonMarriage: return "heart.fill"
        case .besigue: return "star.fill"
        case .fourJacks: return "j.circle.fill"
        case .fourQueens: return "q.circle.fill"
        case .fourKings: return "k.circle.fill"
        case .fourAces: return "a.circle.fill"
        case .fourJokers: return "joker.fill"
        case .sequence: return "list.number"
        }
    }
    
    private func findCard(with id: UUID) -> PlayerCard? {
        return player.cardByID(id)
    }
} 
