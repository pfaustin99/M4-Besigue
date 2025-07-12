import Foundation

// MARK: - Card Suit
enum Suit: String, CaseIterable {
    case hearts = "hearts"
    case diamonds = "diamonds"
    case clubs = "clubs"
    case spades = "spades"
    
    var name: String {
        return self.rawValue
    }
    
    var symbol: String {
        switch self {
        case .hearts: return "♥"
        case .diamonds: return "♦"
        case .clubs: return "♣"
        case .spades: return "♠"
        }
    }
    
    var displayName: String {
        return "\(symbol) \(name.capitalized)"
    }
}

// MARK: - Card Value
enum CardValue: String, CaseIterable {
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case jack = "jack"
    case queen = "queen"
    case king = "king"
    case ten = "10"
    case ace = "ace"
    
    var name: String {
        return self.rawValue
    }
    
    // Point value for brisques (Aces and 10s worth 10 points each)
    var brisqueValue: Int {
        switch self {
        case .ace, .ten:
            return 10
        default:
            return 0
        }
    }
    
    // Rank for trick-taking (higher number wins)
    var rank: Int {
        switch self {
        case .seven: return 1
        case .eight: return 2
        case .nine: return 3
        case .jack: return 4
        case .queen: return 5
        case .king: return 6
        case .ten: return 7
        case .ace: return 8
        }
    }
}

// MARK: - Joker Type
enum JokerType: String, CaseIterable {
    case redOne = "joker_red_1"
    case redTwo = "joker_red_2"
    case blackOne = "joker_black_1"
    case blackTwo = "joker_black_2"
    
    var imageName: String {
        return self.rawValue
    }
}

// MARK: - Card Model
struct Card: Identifiable, Equatable, Hashable {
    let id = UUID()
    let suit: Suit?
    let value: CardValue?
    let jokerType: JokerType?
    let isJoker: Bool
    
    // Regular card initializer
    init(suit: Suit, value: CardValue) {
        self.suit = suit
        self.value = value
        self.jokerType = nil
        self.isJoker = false
    }
    
    // Joker initializer
    init(jokerType: JokerType) {
        self.suit = nil
        self.value = nil
        self.jokerType = jokerType
        self.isJoker = true
    }
    
    // Image name for Assets.xcassets
    var imageName: String {
        if isJoker {
            return jokerType?.imageName ?? "card_back"
        } else {
            guard let suit = suit, let value = value else { return "card_back" }
            return "\(suit.rawValue)_\(value.rawValue)"
        }
    }
    
    // Display name for UI
    var displayName: String {
        if isJoker {
            return jokerType?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "Joker"
        } else {
            guard let suit = suit, let value = value else { return "Unknown" }
            return "\(value.rawValue.capitalized) of \(suit.rawValue.capitalized)"
        }
    }
    
    // Brisque value (for scoring)
    var brisqueValue: Int {
        return value?.brisqueValue ?? 0
    }
    
    // Check if this card is a brisque (Ace or Ten)
    var isBrisque: Bool {
        return value == .ace || value == .ten
    }
    
    // Rank for trick comparison
    var rank: Int {
        return value?.rank ?? 0
    }
    
    // Check if this card can beat another card in a trick
    func canBeat(_ otherCard: Card, trumpSuit: Suit?, leadSuit: Suit?) -> Bool {
        // Jokers can't be played in tricks (used only for melds)
        if isJoker || otherCard.isJoker { 
            print("   🃏 Joker involved - can't beat")
            return false 
        }
        
        guard let mySuit = suit, let myValue = value,
              let otherSuit = otherCard.suit, let otherValue = otherCard.value else {
            print("   ❓ Invalid card data")
            return false
        }
        
        print("   Comparing: \(mySuit.rawValue)_\(myValue.rawValue) vs \(otherSuit.rawValue)_\(otherValue.rawValue)")
        print("   My rank: \(myValue.rank), Other rank: \(otherValue.rank)")
        
        // Trump cards beat non-trump cards
        if let trump = trumpSuit {
            print("   Trump suit: \(trump.rawValue)")
            if mySuit == trump && otherSuit != trump {
                print("   ✅ I'm trump, other isn't - I win")
                return true
            }
            if otherSuit == trump && mySuit != trump {
                print("   ❌ Other is trump, I'm not - I lose")
                return false
            }
        }
        
        // If both cards are same suit, higher rank wins
        if mySuit == otherSuit {
            if myValue.rank > otherValue.rank {
                print("   Same suit (\(mySuit.rawValue)) - I win (rank \(myValue.rank) vs \(otherValue.rank))")
                return true
            } else if myValue.rank < otherValue.rank {
                print("   Same suit (\(mySuit.rawValue)) - I lose (rank \(myValue.rank) vs \(otherValue.rank))")
                return false
            } else {
                // Same rank and suit - this is a tie
                // In card games, the first card played wins ties (trick leader wins)
                print("   Same suit and rank (\(mySuit.rawValue) \(myValue.rawValue)) - TIE, first card wins")
                return false // This card is not the first played, so it doesn't beat the first card
            }
        }
        
        // If different suits and no trump advantage, only same suit as lead can win
        if let lead = leadSuit {
            print("   Lead suit: \(lead.rawValue)")
            if mySuit == lead && otherSuit != lead {
                print("   ✅ I follow lead suit, other doesn't - I win")
                return true
            }
            if otherSuit == lead && mySuit != lead {
                print("   ❌ Other follows lead suit, I don't - I lose")
                return false
            }
        }
        
        print("   ❌ No clear winner - default to false")
        return false
    }
    
    // Simplified canBeat method for tests (without leadSuit)
    func canBeat(_ otherCard: Card, trumpSuit: Suit?) -> Bool {
        return canBeat(otherCard, trumpSuit: trumpSuit, leadSuit: nil)
    }
}

// MARK: - Card Extensions
extension Card {
    // Static methods for creating specific cards
    static func besigueCards() -> [Card] {
        return [
            Card(suit: .spades, value: .queen),
            Card(suit: .diamonds, value: .jack)
        ]
    }
    
    static func royalMarriage(suit: Suit) -> [Card] {
        return [
            Card(suit: suit, value: .king),
            Card(suit: suit, value: .queen)
        ]
    }
    
    static func commonMarriage(suit: Suit) -> [Card] {
        return [
            Card(suit: suit, value: .king),
            Card(suit: suit, value: .queen)
        ]
    }
}

// MARK: - PlayerCard: Card + Meld Usage
struct PlayerCard: Identifiable, Equatable, Hashable {
    let card: Card
    var usedInMeldTypes: Set<MeldType> = []
    
    // Static registry to ensure each Card object creates only one PlayerCard instance
    private static var cardRegistry: [UUID: PlayerCard] = [:]
    private static let registryLock = NSLock()
    
    var id: UUID { card.id }
    var suit: Suit? { card.suit }
    var value: CardValue? { card.value }
    var isJoker: Bool { card.isJoker }
    var imageName: String { card.imageName }
    var displayName: String { card.displayName }
    var brisqueValue: Int { card.brisqueValue }
    var rank: Int { card.rank }
    var isBrisque: Bool { card.isBrisque }
    
    // Initialize PlayerCard with registry to ensure singleton instances
    init(card: Card) {
        self.card = card
        self.usedInMeldTypes = []
    }
    
    // Check if this card can beat another card in a trick
    func canBeat(_ otherCard: PlayerCard, trumpSuit: Suit?, leadSuit: Suit?) -> Bool {
        return card.canBeat(otherCard.card, trumpSuit: trumpSuit, leadSuit: leadSuit)
    }
    
    // Simplified canBeat method for tests (without leadSuit)
    func canBeat(_ otherCard: PlayerCard, trumpSuit: Suit?) -> Bool {
        return card.canBeat(otherCard.card, trumpSuit: trumpSuit)
    }
    
    // Static method to clear registry (useful for testing or game reset)
    static func clearRegistry() {
        registryLock.lock()
        defer { registryLock.unlock() }
        cardRegistry.removeAll()
    }
    
    // Static method to get existing PlayerCard instance or create new one
    static func getOrCreate(for card: Card) -> PlayerCard {
        registryLock.lock()
        defer { registryLock.unlock() }
        
        if let existing = cardRegistry[card.id] {
            return existing
        } else {
            let newPlayerCard = PlayerCard(card: card)
            cardRegistry[card.id] = newPlayerCard
            return newPlayerCard
        }
    }
}

extension PlayerCard {
    static let example = PlayerCard(card: Card(suit: .spades, value: .queen))
}
