import Foundation

// MARK: - Player Model
class Player: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let type: PlayerType
    @Published var hand: [PlayerCard] = []
    @Published var score: Int = 0
    @Published var tricksWon: Int = 0
    @Published var meldsDeclared: [Meld] = []
    @Published var isDealer: Bool = false
    @Published var isCurrentPlayer: Bool = false
    
    init(name: String, type: PlayerType) {
        self.name = name
        self.type = type
    }
    
    // Add cards to hand
    func addCards(_ cards: [Card]) {
        hand.append(contentsOf: cards.map { PlayerCard(card: $0) })
    }
    
    // Remove card from hand
    func removeCard(_ card: PlayerCard) {
        if let index = hand.firstIndex(of: card) {
            hand.remove(at: index)
        }
    }
    
    // Check if player has a specific card
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
        print("     All cards: \(hand.map { $0.displayName })")
        
        // If no lead suit, all cards are playable
        guard let leadSuit = leadSuit else {
            print("     No lead suit - all cards playable")
            return hand
        }
        
        // If player can follow suit, they must play a card of that suit
        if canFollowSuit(leadSuit: leadSuit) {
            let suitCards = cardsOfSuit(leadSuit)
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
        meldsDeclared.append(meld)
        addPoints(meld.pointValue)
        
        // Remove the melded cards from the player's hand (only if they're still there)
        for i in 0..<meld.cards.count {
            removeCard(meld.cards[i])
        }
        
        // Mark meld usage on the involved PlayerCards (in hand and in melds)
        for i in 0..<meld.cards.count {
            let card = meld.cards[i]
            // Update in hand
            if let idx = hand.firstIndex(of: card) {
                hand[idx].usedInMeldTypes.insert(meld.type)
            }
            // Update in melds
            for meldIdx in 0..<meldsDeclared.count {
                if let cardIdx = meldsDeclared[meldIdx].cards.firstIndex(of: card) {
                    meldsDeclared[meldIdx].cards[cardIdx].usedInMeldTypes.insert(meld.type)
                }
            }
        }
        
        print("🎴 \(name) declared \(meld.type.name) with \(meld.cards.count) cards")
        print("   Cards removed from hand: \(meld.cards.map { $0.displayName })")
        print("   Remaining hand size: \(hand.count)")
        print("   Total melds: \(meldsDeclared.count)")
    }
    
    // Reset player for new game
    func reset() {
        hand.removeAll()
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
}

// MARK: - Meld Model
/// Represents a meld declared by a player in Bésigue.
struct Meld: Identifiable, Equatable {
    let id = UUID()
    var cards: [PlayerCard]
    let type: MeldType
    let pointValue: Int // Now set dynamically from GameSettings
    let roundNumber: Int // Track the round when the meld was declared
    
    init(cards: [PlayerCard], type: MeldType, pointValue: Int, roundNumber: Int) {
        self.cards = cards
        self.type = type
        self.pointValue = pointValue
        self.roundNumber = roundNumber
    }
    
    // Convenience initializer for tests
    init(type: MeldType, cards: [PlayerCard], points: Int) {
        self.cards = cards
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