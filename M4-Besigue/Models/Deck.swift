import Foundation

// MARK: - Deck Model
class Deck: ObservableObject {
    @Published var cards: [Card] = []
    @Published var discardPile: [Card] = []
    
    init() {
        createBesigueDeck()
        shuffle()
    }
    
    // Create the 132-card Bésigue deck (4 x 32-card Piquet decks + 4 Jokers)
    private func createBesigueDeck() {
        cards.removeAll()
        
        // Create 4 copies of each regular card (4 x 32 = 128 cards)
        for _ in 1...4 {
            for suit in Suit.allCases {
                for value in CardValue.allCases {
                    cards.append(Card(suit: suit, value: value))
                }
            }
        }
        
        // Add 4 Jokers
        cards.append(Card(jokerType: .redOne))
        cards.append(Card(jokerType: .redTwo))
        cards.append(Card(jokerType: .blackOne))
        cards.append(Card(jokerType: .blackTwo))
        
        print("Created Bésigue deck with \(cards.count) cards")
    }
    
    // Shuffle the deck
    func shuffle() {
        cards.shuffle()
    }
    
    // Draw a card from the top of the deck
    func drawCard() -> Card? {
        guard !cards.isEmpty else { return nil }
        return cards.removeFirst()
    }
    
    // Draw multiple cards
    func drawCards(count: Int) -> [Card] {
        var drawnCards: [Card] = []
        for _ in 0..<count {
            if let card = drawCard() {
                drawnCards.append(card)
            }
        }
        return drawnCards
    }
    
    // Deal cards to players (9 cards each, dealt 3 at a time)
    func dealCards(to playerCount: Int) -> [[Card]] {
        var playerHands: [[Card]] = Array(repeating: [], count: playerCount)
        
        // Deal 3 rounds of 3 cards each (total 9 cards per player)
        for _ in 0..<3 {
            for _ in 0..<3 {
                for playerIndex in 0..<playerCount {
                    if let card = drawCard() {
                        playerHands[playerIndex].append(card)
                    }
                }
            }
        }
        
        return playerHands
    }
    
    // Check if deck is empty
    var isEmpty: Bool {
        return cards.isEmpty
    }
    
    // Number of cards remaining
    var remainingCount: Int {
        return cards.count
    }
    
    // Add card to discard pile
    func discard(_ card: Card) {
        discardPile.append(card)
    }
    
    // Reset deck (useful for new games)
    func reset() {
        discardPile.removeAll()
        createBesigueDeck()
        shuffle()
    }
    
    // Find the first Jack to determine initial dealer
    func findFirstJackDrawer(playerCount: Int) -> Int {
        var tempDeck = cards
        var currentPlayer = 0
        
        while !tempDeck.isEmpty {
            let card = tempDeck.removeFirst()
            if !card.isJoker && card.value == .jack {
                return currentPlayer
            }
            currentPlayer = (currentPlayer + 1) % playerCount
        }
        
        // If no Jack found (shouldn't happen), return random player
        return Int.random(in: 0..<playerCount)
    }
    
    // Debug method to print deck contents
    func printDeckContents() {
        print("=== DECK CONTENTS ===")
        print("Total cards: \(cards.count)")
        
        var cardCounts: [String: Int] = [:]
        for card in cards {
            let key = card.imageName
            cardCounts[key, default: 0] += 1
        }
        
        for (cardName, count) in cardCounts.sorted(by: { $0.key < $1.key }) {
            print("\(cardName): \(count)")
        }
        print("====================")
    }
}

// MARK: - Deck Extensions
extension Deck {
    // Verify deck composition is correct
    func verifyDeckComposition() -> Bool {
        let expectedTotalCards = 132
        guard cards.count + discardPile.count == expectedTotalCards else {
            print("❌ Deck verification failed: Total cards = \(cards.count + discardPile.count), expected \(expectedTotalCards)")
            return false
        }
        
        // Count regular cards (should be 4 of each)
        var regularCardCounts: [String: Int] = [:]
        var jokerCount = 0
        
        let allCards = cards + discardPile
        
        for card in allCards {
            if card.isJoker {
                jokerCount += 1
            } else {
                let key = "\(card.suit?.rawValue ?? "")_\(card.value?.rawValue ?? "")"
                regularCardCounts[key, default: 0] += 1
            }
        }
        
        // Check joker count
        guard jokerCount == 4 else {
            print("❌ Deck verification failed: Joker count = \(jokerCount), expected 4")
            return false
        }
        
        // Check regular card counts (should be exactly 4 of each)
        for suit in Suit.allCases {
            for value in CardValue.allCases {
                let key = "\(suit.rawValue)_\(value.rawValue)"
                let count = regularCardCounts[key, default: 0]
                guard count == 4 else {
                    print("❌ Deck verification failed: \(key) count = \(count), expected 4")
                    return false
                }
            }
        }
        
        print("✅ Deck composition verified successfully")
        return true
    }
}
