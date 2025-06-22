import Foundation

// MARK: - Player Type
enum PlayerType {
    case human
    case ai
}

// MARK: - Player Model
class Player: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let type: PlayerType
    @Published var hand: [Card] = []
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
        hand.append(contentsOf: cards)
    }
    
    // Remove card from hand
    func removeCard(_ card: Card) {
        if let index = hand.firstIndex(of: card) {
            hand.remove(at: index)
        }
    }
    
    // Check if player has a specific card
    func hasCard(_ card: Card) -> Bool {
        return hand.contains(card)
    }
    
    // Get cards of a specific suit
    func cardsOfSuit(_ suit: Suit) -> [Card] {
        return hand.filter { !$0.isJoker && $0.suit == suit }
    }
    
    // Get all non-joker cards
    var regularCards: [Card] {
        return hand.filter { !$0.isJoker }
    }
    
    // Get all joker cards
    var jokerCards: [Card] {
        return hand.filter { $0.isJoker }
    }
    
    // Check if player can follow suit (has cards of the lead suit)
    func canFollowSuit(leadSuit: Suit) -> Bool {
        return !cardsOfSuit(leadSuit).isEmpty
    }
    
    // Get playable cards based on lead suit and trump
    func getPlayableCards(leadSuit: Suit?, trumpSuit: Suit?) -> [Card] {
        // If no lead suit, all cards are playable
        guard let leadSuit = leadSuit else {
            return hand
        }
        
        // If player can follow suit, they must play a card of that suit
        if canFollowSuit(leadSuit: leadSuit) {
            return cardsOfSuit(leadSuit)
        }
        
        // If they can't follow suit, they can play any card
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
        return score + meldPoints
    }
}

// MARK: - Meld Model
struct Meld: Identifiable, Equatable {
    let id = UUID()
    let cards: [Card]
    let type: MeldType
    let pointValue: Int
    
    init(cards: [Card], type: MeldType) {
        self.cards = cards
        self.type = type
        self.pointValue = type.pointValue
    }
}

// MARK: - Meld Types
enum MeldType: CaseIterable {
    case besigue // Queen of Spades + Jack of Diamonds (40 points)
    case royalMarriage // King + Queen of same suit (40 points)
    case commonMarriage // King + Queen of same suit (20 points)
    case fourOfAKind // Four cards of same rank (100 points)
    case fourJacks // Four Jacks (40 points)
    case fourQueens // Four Queens (60 points)
    case fourKings // Four Kings (80 points)
    case fourAces // Four Aces (100 points)
    
    var pointValue: Int {
        switch self {
        case .besigue: return 40
        case .royalMarriage: return 40
        case .commonMarriage: return 20
        case .fourOfAKind: return 100
        case .fourJacks: return 40
        case .fourQueens: return 60
        case .fourKings: return 80
        case .fourAces: return 100
        }
    }
    
    var name: String {
        switch self {
        case .besigue: return "Bésigue"
        case .royalMarriage: return "Royal Marriage"
        case .commonMarriage: return "Common Marriage"
        case .fourOfAKind: return "Four of a Kind"
        case .fourJacks: return "Four Jacks"
        case .fourQueens: return "Four Queens"
        case .fourKings: return "Four Kings"
        case .fourAces: return "Four Aces"
        }
    }
} 