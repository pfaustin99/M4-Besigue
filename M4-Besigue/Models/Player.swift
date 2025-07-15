import Foundation

// MARK: - Player Model
class Player: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let type: PlayerType
    @Published var held: [PlayerCard] = []
    @Published var melded: [PlayerCard] = [] // Unique melded cards, orderable for drag-and-drop
    
    // User-driven order for melded cards
    @Published var meldedOrder: [UUID] = []
    
    // Computed property: hand = held + melded cards (unique by UUID)
    var hand: [PlayerCard] {
        let allCards = held + melded
        var seen = Set<UUID>()
        var unique: [PlayerCard] = []
        for card in allCards {
            if !seen.contains(card.id) {
                unique.append(card)
                seen.insert(card.id)
            }
        }
        return unique
    }
    
    @Published var score: Int = 0
    @Published var tricksWon: Int = 0
    @Published var meldsDeclared: [Meld] = []
    @Published var isDealer: Bool = false
    @Published var isCurrentPlayer: Bool = false
    
    init(name: String, type: PlayerType) {
        self.name = name
        self.type = type
    }
    
    // Add cards to held
    func addCards(_ cards: [Card]) {
        print("🎴 \(name) adding \(cards.count) cards to held:")
        for card in cards {
            print("   \(card.displayName) (ID: \(card.id))")
        }
        
        let newPlayerCards = cards.map { PlayerCard(card: $0) }
        held.append(contentsOf: newPlayerCards)
        
        print("🎴 \(name) held cards after adding:")
        for playerCard in held {
            print("   \(playerCard.displayName) (ID: \(playerCard.id))")
        }
    }
    
    // Remove card from held or melds
    func removeCard(_ card: PlayerCard) {
        // Remove from held if present
        if let index = held.firstIndex(of: card) {
            held.remove(at: index)
            print("🎴 \(name) removed \(card.displayName) from held")
            return
        }
        
        // Remove from melded array if present
        if let meldedIndex = melded.firstIndex(where: { $0.id == card.id }) {
            melded.remove(at: meldedIndex)
            print("🎴 \(name) removed \(card.displayName) from melded array")
            
            // Also remove from meldedOrder
            if let orderIndex = meldedOrder.firstIndex(of: card.id) {
                meldedOrder.remove(at: orderIndex)
                print("🎴 \(name) removed \(card.displayName) from melded order")
            }
            
            // Update meldsDeclared to remove this card from all melds
            for meldIndex in 0..<meldsDeclared.count {
                if let cardIndex = meldsDeclared[meldIndex].cardIDs.firstIndex(of: card.id) {
                    meldsDeclared[meldIndex].cardIDs.remove(at: cardIndex)
                    print("🎴 \(name) removed \(card.displayName) from meld \(meldsDeclared[meldIndex].type.name)")
                    
                    // If meld is now empty, remove the entire meld
                    if meldsDeclared[meldIndex].cardIDs.isEmpty {
                        meldsDeclared.remove(at: meldIndex)
                        print("🎴 \(name) removed empty meld")
                    }
                }
            }
            return
        }
        
        print("⚠️ \(name) tried to remove \(card.displayName) but card not found in held or melded")
    }
    
    // Check if player has a specific card (in hand - held or melded)
    func hasCard(_ card: PlayerCard) -> Bool {
        return hand.contains(card)
    }
    
    // Get cards of a specific suit
    func cardsOfSuit(_ suit: Suit) -> [PlayerCard] {
        return hand.filter { !$0.isJoker && $0.suit == suit }
    }
    
    // Get all non-joker cards
    var regularCards: [PlayerCard] {
        return hand.filter { !$0.isJoker }
    }
    
    // Get all joker cards
    var jokerCards: [PlayerCard] {
        return hand.filter { $0.isJoker }
    }
    
    // Check if player can follow suit (has cards of the lead suit)
    func canFollowSuit(leadSuit: Suit) -> Bool {
        return !cardsOfSuit(leadSuit).isEmpty
    }
    
    // Get playable cards based on lead suit and trump
    func getPlayableCards(leadSuit: Suit?, trumpSuit: Suit?) -> [PlayerCard] {
        print("   🎴 Player \(name) getPlayableCards:")
        print("     Lead suit: \(leadSuit?.rawValue ?? "None")")
        print("     Trump suit: \(trumpSuit?.rawValue ?? "None")")
        
        // Use the computed hand property (held + melded)
        print("     All cards (hand): \(hand.map { $0.displayName })")
        
        // If no lead suit, all cards are playable
        guard let leadSuit = leadSuit else {
            print("     No lead suit - all cards playable")
            return hand
        }
        
        // If player can follow suit, they must play a card of that suit
        let suitCards = hand.filter { !$0.isJoker && $0.suit == leadSuit }
        if !suitCards.isEmpty {
            print("     Can follow suit \(leadSuit.rawValue) - must play: \(suitCards.map { $0.displayName })")
            return suitCards
        }
        
        // If they can't follow suit, they can play any card
        print("     Cannot follow suit \(leadSuit.rawValue) - can play any card")
        return hand
    }
    
    // Add points to score
    func addPoints(_ points: Int) {
        score += points
    }
    
    // Add a meld to the player's declared melds
    func declareMeld(_ meld: Meld) {
        // For each card UUID in meld.cardIDs:
        for cardID in meld.cardIDs {
            // Find the PlayerCard in held or melded
            if let heldIndex = held.firstIndex(where: { $0.id == cardID }) {
                let card = held.remove(at: heldIndex)
                if !melded.contains(where: { $0.id == cardID }) {
                    melded.append(card)
                }
                // Update usedInMeldTypes
                if let meldedIndex = melded.firstIndex(where: { $0.id == cardID }) {
                    melded[meldedIndex].usedInMeldTypes.insert(meld.type)
                }
            } else if let meldedIndex = melded.firstIndex(where: { $0.id == cardID }) {
                melded[meldedIndex].usedInMeldTypes.insert(meld.type)
            } else {
                print("⚠️ Card with ID \(cardID) not found in held or melded when declaring meld.")
            }
            // Update meldedOrder: add new cards to the end if not already present
            if !meldedOrder.contains(cardID) {
                meldedOrder.append(cardID)
            }
        }
        meldsDeclared.append(meld)
        addPoints(meld.pointValue)
        print("🎴 \(name) declared \(meld.type.name) with \(meld.cardIDs.count) cards")
        print("   Cards moved from held to meld: \(meld.cardIDs)")
        print("   Remaining held cards: \(held.count)")
        print("   Total melds: \(meldsDeclared.count)")
        print("   Melded order: \(meldedOrder.count) cards")
    }
    
    // Get melded cards in user-defined order
    func getMeldedCardsInOrder() -> [PlayerCard] {
        // Use meldedOrder to order melded cards
        var orderedCards: [PlayerCard] = []
        // Add cards in the order specified by meldedOrder
        for cardId in meldedOrder {
            if let card = melded.first(where: { $0.id == cardId }) {
                orderedCards.append(card)
            }
        }
        // Add any cards that might not be in meldedOrder (fallback)
        for card in melded {
            if !orderedCards.contains(card) {
                orderedCards.append(card)
            }
        }
        return orderedCards
    }
    
    // Update melded card order (called when user drags and drops)
    func updateMeldedOrder(_ newOrder: [UUID]) {
        meldedOrder = newOrder
    }
    
    // Update held card order (called when user drags and drops)
    func updateHeldOrder(_ newOrder: [PlayerCard]) {
        held = newOrder
    }
    
    // Reset player for new game
    func reset() {
        held.removeAll()
        meldedOrder.removeAll()
        score = 0
        tricksWon = 0
        meldsDeclared.removeAll()
        isDealer = false
        isCurrentPlayer = false
    }
    
    // Get total points from melds
    var meldPoints: Int {
        return meldsDeclared.reduce(0) { $0 + $1.pointValue }
    }
    
    // Get total points (melds + brisques)
    var totalPoints: Int {
        return score
    }
    
    // Helper: Look up a PlayerCard by UUID from held or melded
    func cardByID(_ id: UUID) -> PlayerCard? {
        if let card = held.first(where: { $0.id == id }) {
            return card
        }
        if let card = melded.first(where: { $0.id == id }) {
            return card
        }
        return nil
    }
}

// MARK: - Meld Model
/// Represents a meld declared by a player in Bésigue.
struct Meld: Identifiable, Equatable {
    let id = UUID()
    let type: MeldType
    let pointValue: Int // Now set dynamically from GameSettings
    let roundNumber: Int // Track the round when the meld was declared
    var cardIDs: [UUID] // Store only UUIDs, not PlayerCard objects

    init(cardIDs: [UUID], type: MeldType, pointValue: Int, roundNumber: Int) {
        self.cardIDs = cardIDs
        self.type = type
        self.pointValue = pointValue
        self.roundNumber = roundNumber
    }
    
    // Convenience initializer for tests
    init(type: MeldType, cardIDs: [UUID], points: Int) {
        self.cardIDs = cardIDs
        self.type = type
        self.pointValue = points
        self.roundNumber = 1 // Default round number for tests
    }
}

// MARK: - Meld Types
/// Types of melds in Bésigue. Points should be sourced from GameSettings.
enum MeldType: String, CaseIterable, Codable, Hashable {
    case besigue
    case royalMarriage
    case commonMarriage
    case fourJacks
    case fourQueens
    case fourKings
    case fourAces
    case fourJokers
    case sequence
    
    var name: String {
        switch self {
        case .besigue: return "Bésigue"
        case .royalMarriage: return "Royal Marriage"
        case .commonMarriage: return "Common Marriage"
        case .fourJacks: return "Four Jacks"
        case .fourQueens: return "Four Queens"
        case .fourKings: return "Four Kings"
        case .fourAces: return "Four Aces"
        case .fourJokers: return "Four Jokers"
        case .sequence: return "Sequence"
        }
    }
    
    /// Helper for four-of-a-kind melds
    static func forValue(_ value: CardValue) -> MeldType? {
        switch value {
        case .jack: return .fourJacks
        case .queen: return .fourQueens
        case .king: return .fourKings
        case .ace: return .fourAces
        default: return nil
        }
    }
} 