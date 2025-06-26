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
        // Mark meld usage on the involved PlayerCards
        for card in meld.cards {
            if let idx = hand.firstIndex(of: card) {
                hand[idx].usedInMeldTypes.insert(meld.type)
            }
        }
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
struct Meld: Identifiable, Equatable {
    let id = UUID()
    let cards: [PlayerCard]
    let type: MeldType
    let pointValue: Int
    let roundNumber: Int // Track the round when the meld was declared
    
    init(cards: [PlayerCard], type: MeldType, roundNumber: Int) {
        self.cards = cards
        self.type = type
        self.pointValue = type.pointValue
        self.roundNumber = roundNumber
    }
}

// MARK: - Meld Types
enum MeldType: CaseIterable {
    case besigue // Queen of Spades + Jack of Diamonds (40 points)
    case royalMarriage // King + Queen of same suit (40 points)
    case commonMarriage // King + Queen of same suit (20 points)
    case fourJacks // Four Jacks (40 points)
    case fourQueens // Four Queens (60 points)
    case fourKings // Four Kings (80 points)
    case fourAces // Four Aces (100 points)
    case fourJokers // Four Jokers (200 points)
    case sequence // Ace, 10, King, Queen, Jack of trump suit (250 points)
    
    var pointValue: Int {
        switch self {
        case .besigue: return 40
        case .royalMarriage: return 40
        case .commonMarriage: return 20
        case .fourJacks: return 40
        case .fourQueens: return 60
        case .fourKings: return 80
        case .fourAces: return 100
        case .fourJokers: return 200
        case .sequence: return 250
        }
    }
    
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
    
    static func forValue(_ value: CardValue) -> MeldType {
        switch value {
        case .jack: return .fourJacks
        case .queen: return .fourQueens
        case .king: return .fourKings
        case .ace: return .fourAces
        default: fatalError("No four-of-a-kind meld for this value")
        }
    }
} 