import Foundation

// MARK: - Player Model
class Player: ObservableObject, Identifiable {
    var id = UUID()
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
        // Enforce 12-character limit for consistent layouts
        let trimmedName = String(name.prefix(12))
        self.name = trimmedName
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
            for meldIndex in (0..<meldsDeclared.count).reversed() {
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
        let oldScore = score
        score += points
        print("💰 SCORE UPDATE: \(name)")
        print("   Old score: \(oldScore)")
        print("   Points added: \(points)")
        print("   New score: \(score)")
        print("   @Published score property updated: \(score)")
    }
    
    // Moves only held cards into `melded`. If a card is already in `melded`, it is not duplicated.
    // For all referenced cards (held or already-melded), mark usage and update meldedOrder once.
    // Missing IDs are logged and ignored (defensive).
    func declareMeld(_ meld: Meld) {
        // PURPOSE: Only move cards from `held` to `melded` for this meld.
        //          Cards already in `melded` must NOT be duplicated.
        //          All referenced cards (held + already-melded) should have their
        //          `usedInMeldTypes` updated and appear once in `meldedOrder`.

        // 0) Sanitize input: de-duplicate requested IDs while preserving order.
        var seen = Set<UUID>()
        let requestedIDs = meld.cardIDs.filter { seen.insert($0).inserted }

        // 1) Snapshot membership sets to partition the request quickly.
        let heldIDs   = Set(held.map { $0.id })
        let meldedIDs = Set(melded.map { $0.id })

        var idsFromHeld: [UUID] = []
        var idsFromMelded: [UUID] = []
        var idsMissing: [UUID] = []

        for id in requestedIDs {
            if heldIDs.contains(id) {
                idsFromHeld.append(id)
            } else if meldedIDs.contains(id) {
                idsFromMelded.append(id)
            } else {
                // Defensive: UI/AI should only send IDs that exist.
                idsMissing.append(id)
            }
        }

        if !idsMissing.isEmpty {
            print("⚠️ declareMeld: some IDs not found in held or melded for \(name): \(idsMissing)")
            // Proceed with known cards; this keeps the method tolerant to minor UI desyncs.
        }

        // 2) Move ONLY the held cards into `melded` (no duplicates by ID).
        //    Collect removed cards in the same order as requested.
        var movedCards: [PlayerCard] = []
        for id in idsFromHeld {
            if let idx = held.firstIndex(where: { $0.id == id }) {
                let card = held.remove(at: idx)
                if !melded.contains(where: { $0.id == card.id }) {
                    movedCards.append(card)
                } else {
                    // Extremely defensive: if the card is already present in `melded`, skip appending.
                    print("⚠️ declareMeld: \(card.displayName) already in melded; skipping append")
                }
            }
        }
        // Append all newly moved cards in order.
        melded.append(contentsOf: movedCards)

        // 3) Mark usage for ALL referenced cards (those we just moved and those already in `melded`).
        for id in (idsFromHeld + idsFromMelded) {
            if let mIdx = melded.firstIndex(where: { $0.id == id }) {
                melded[mIdx].usedInMeldTypes.insert(meld.type)
            } else {
                // If it was from held, it should now be in melded; if from melded, it should have been present.
                // Log defensively if not found.
                print("⚠️ declareMeld: could not mark usage for id \(id) in melded")
            }
        }

        // 4) Maintain user-visible melded order (append each once, following the incoming order).
       // for id in requestedIDs where !meldedOrder.contains(id) {
        for id in requestedIDs where !meldedOrder.contains(id) && idsFromHeld.contains(id) {
            meldedOrder.append(id)
        }

        // 5) Record a sanitized copy of the meld (unique card IDs only) and award points.
        let recorded = Meld(cardIDs: requestedIDs, type: meld.type, pointValue: meld.pointValue, roundNumber: meld.roundNumber)
        meldsDeclared.append(recorded)
        addPoints(meld.pointValue)

        // 6) Logging for debugging / analytics.
        print("🎴 \(name) declared \(meld.type.name) with \(requestedIDs.count) unique cards")
        print("   Moved from held → melded: \(idsFromHeld)")
        print("   Referenced already in melded: \(idsFromMelded)")
        print("   Remaining held: \(held.count), Melded: \(melded.count), MeldedOrder: \(meldedOrder.count)")
    }
    
    // Get melded cards in user-defined order
    func getMeldedCardsInOrder() -> [PlayerCard] {
        // Build an ordered list of melded cards based on `meldedOrder`,
        // then append any remaining melded cards we didn’t list yet.
        var ordered: [PlayerCard] = []
        var seen = Set<UUID>()

        // First, take cards in the explicit user-defined order.
        for id in meldedOrder {
            if let card = melded.first(where: { $0.id == id }), seen.insert(id).inserted {
                ordered.append(card)
            }
        }
        // Then, include any other melded cards not yet included (by ID).
        for card in melded {
            if seen.insert(card.id).inserted {
                ordered.append(card)
            }
        }
        return ordered
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
