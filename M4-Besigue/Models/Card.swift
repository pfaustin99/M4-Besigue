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
    
    // Rank for trick comparison
    var rank: Int {
        return value?.rank ?? 0
    }
    
    // Check if this card can beat another card in a trick
    func canBeat(_ otherCard: Card, trumpSuit: Suit?, leadSuit: Suit?) -> Bool {
        // Jokers can't be played in tricks (used only for melds)
        if isJoker || otherCard.isJoker { return false }
        
        guard let mySuit = suit, let myValue = value,
              let otherSuit = otherCard.suit, let otherValue = otherCard.value else {
            return false
        }
        
        // Trump cards beat non-trump cards
        if let trump = trumpSuit {
            if mySuit == trump && otherSuit != trump {
                return true
            }
            if otherSuit == trump && mySuit != trump {
                return false
            }
        }
        
        // If both cards are same suit, higher rank wins
        if mySuit == otherSuit {
            return myValue.rank > otherValue.rank
        }
        
        // If different suits and no trump advantage, only same suit as lead can win
        if let lead = leadSuit {
            if mySuit == lead && otherSuit != lead {
                return true
            }
        }
        
        return false
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
