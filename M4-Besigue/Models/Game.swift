import Foundation

// MARK: - Game Phase
enum GamePhase {
    case setup
    case dealing
    case melding
    case playing
    case scoring
    case gameOver
}

// MARK: - Game Model
class Game: ObservableObject {
    @Published var players: [Player] = []
    @Published var deck: Deck
    @Published var currentPhase: GamePhase = .setup
    @Published var currentPlayerIndex: Int = 0
    @Published var trumpSuit: Suit?
    @Published var currentTrick: [Card] = []
    @Published var currentTrickLeader: Int = 0
    @Published var trickHistory: [[Card]] = []
    @Published var roundNumber: Int = 1
    @Published var gameNumber: Int = 1
    @Published var winningScore: Int = 1000 // Default winning score
    
    // Game settings
    let playerCount: Int
    let isOnline: Bool
    
    init(playerCount: Int = 2, isOnline: Bool = false) {
        self.playerCount = playerCount
        self.isOnline = isOnline
        self.deck = Deck()
        setupPlayers()
    }
    
    // Setup players for the game
    private func setupPlayers() {
        players.removeAll()
        
        // Create human player
        players.append(Player(name: "You", type: .human))
        
        // Create AI players
        for i in 1..<playerCount {
            players.append(Player(name: "AI Player \(i)", type: .ai))
        }
    }
    
    // Start a new game
    func startNewGame() {
        // Reset all players
        for player in players {
            player.reset()
        }
        
        // Reset game state
        deck.reset()
        currentPhase = .dealing
        currentPlayerIndex = 0
        trumpSuit = nil
        currentTrick.removeAll()
        currentTrickLeader = 0
        trickHistory.removeAll()
        roundNumber = 1
        
        // Determine dealer (first Jack drawn)
        let dealerIndex = deck.findFirstJackDrawer(playerCount: playerCount)
        players[dealerIndex].isDealer = true
        
        // Deal cards
        dealCards()
        
        // Move to melding phase
        currentPhase = .melding
    }
    
    // Deal cards to all players
    private func dealCards() {
        let playerHands = deck.dealCards(to: playerCount)
        
        for (index, hand) in playerHands.enumerated() {
            players[index].addCards(hand)
        }
        
        print("Dealt \(playerHands[0].count) cards to each player")
    }
    
    // Get current player
    var currentPlayer: Player {
        return players[currentPlayerIndex]
    }
    
    // Move to next player
    func nextPlayer() {
        currentPlayerIndex = (currentPlayerIndex + 1) % playerCount
        currentPlayer.isCurrentPlayer = true
        
        // Clear previous player's current status
        for (index, player) in players.enumerated() {
            if index != currentPlayerIndex {
                player.isCurrentPlayer = false
            }
        }
    }
    
    // Start a new trick
    func startNewTrick() {
        currentTrick.removeAll()
        currentTrickLeader = currentPlayerIndex
        currentPhase = .playing
    }
    
    // Play a card
    func playCard(_ card: Card, from player: Player) {
        // Remove card from player's hand
        player.removeCard(card)
        
        // Add to current trick
        currentTrick.append(card)
        
        // Check if trick is complete
        if currentTrick.count == playerCount {
            completeTrick()
        } else {
            nextPlayer()
        }
    }
    
    // Complete the current trick
    private func completeTrick() {
        // Determine winner of the trick
        let winnerIndex = determineTrickWinner()
        let winner = players[winnerIndex]
        
        // Award the trick
        winner.tricksWon += 1
        
        // Add brisque points (Aces and 10s)
        for card in currentTrick {
            winner.addPoints(card.brisqueValue)
        }
        
        // Store trick in history
        trickHistory.append(currentTrick)
        
        // Set winner as next player
        currentPlayerIndex = winnerIndex
        currentPlayer.isCurrentPlayer = true
        
        // Clear current trick
        currentTrick.removeAll()
        
        // Check if round is over
        if allPlayersHaveEmptyHands() {
            endRound()
        } else {
            startNewTrick()
        }
    }
    
    // Determine winner of current trick
    private func determineTrickWinner() -> Int {
        guard !currentTrick.isEmpty else { return currentTrickLeader }
        
        var winningCard = currentTrick[0]
        var winningPlayerIndex = currentTrickLeader
        
        for (index, card) in currentTrick.enumerated() {
            let playerIndex = (currentTrickLeader + index) % playerCount
            if card.canBeat(winningCard, trumpSuit: trumpSuit, leadSuit: currentTrick.first?.suit) {
                winningCard = card
                winningPlayerIndex = playerIndex
            }
        }
        
        return winningPlayerIndex
    }
    
    // Check if all players have empty hands
    private func allPlayersHaveEmptyHands() -> Bool {
        return players.allSatisfy { $0.hand.isEmpty }
    }
    
    // End the current round
    private func endRound() {
        currentPhase = .scoring
        
        // Calculate final scores
        calculateFinalScores()
        
        // Check if game is over
        if hasWinner() {
            currentPhase = .gameOver
        } else {
            // Start new round
            roundNumber += 1
            startNewGame()
        }
    }
    
    // Calculate final scores for the round
    private func calculateFinalScores() {
        for player in players {
            // Add meld points (already added during declaration)
            // Add trick points (already added during play)
            // Add brisque points (already added during play)
            
            print("\(player.name): \(player.totalPoints) points")
        }
    }
    
    // Check if there's a winner
    private func hasWinner() -> Bool {
        return players.contains { $0.totalPoints >= winningScore }
    }
    
    // Get the winner
    var winner: Player? {
        return players.first { $0.totalPoints >= winningScore }
    }
    
    // Set trump suit
    func setTrumpSuit(_ suit: Suit) {
        trumpSuit = suit
    }
    
    // Get playable cards for current player
    func getPlayableCards() -> [Card] {
        let leadSuit = currentTrick.first?.suit
        return currentPlayer.getPlayableCards(leadSuit: leadSuit, trumpSuit: trumpSuit)
    }
    
    // Check if a meld can be declared
    func canDeclareMeld(_ meld: Meld, by player: Player) -> Bool {
        // Check if player has all the cards in the meld
        for card in meld.cards {
            if !player.hasCard(card) {
                return false
            }
        }
        
        // Check if meld hasn't been declared before
        return !player.meldsDeclared.contains { $0.type == meld.type }
    }
    
    // Declare a meld
    func declareMeld(_ meld: Meld, by player: Player) {
        if canDeclareMeld(meld, by: player) {
            player.declareMeld(meld)
            print("\(player.name) declared \(meld.type.name) for \(meld.pointValue) points")
        }
    }
    
    // Get all possible melds for a player
    func getPossibleMelds(for player: Player) -> [Meld] {
        var possibleMelds: [Meld] = []
        
        // Check for Bésigue
        if let besigueMeld = checkForBesigue(in: player.hand) {
            possibleMelds.append(besigueMeld)
        }
        
        // Check for marriages
        possibleMelds.append(contentsOf: checkForMarriages(in: player.hand))
        
        // Check for four of a kind
        possibleMelds.append(contentsOf: checkForFourOfAKind(in: player.hand))
        
        return possibleMelds
    }
    
    // Check for Bésigue meld
    private func checkForBesigue(in hand: [Card]) -> Meld? {
        let queenOfSpades = hand.first { $0.suit == .spades && $0.value == .queen }
        let jackOfDiamonds = hand.first { $0.suit == .diamonds && $0.value == .jack }
        
        if let queen = queenOfSpades, let jack = jackOfDiamonds {
            return Meld(cards: [queen, jack], type: .besigue)
        }
        
        return nil
    }
    
    // Check for marriage melds
    private func checkForMarriages(in hand: [Card]) -> [Meld] {
        var marriages: [Meld] = []
        
        for suit in Suit.allCases {
            let king = hand.first { $0.suit == suit && $0.value == .king }
            let queen = hand.first { $0.suit == suit && $0.value == .queen }
            
            if let king = king, let queen = queen {
                let isTrump = suit == trumpSuit
                let meldType: MeldType = isTrump ? .royalMarriage : .commonMarriage
                marriages.append(Meld(cards: [king, queen], type: meldType))
            }
        }
        
        return marriages
    }
    
    // Check for four of a kind melds
    private func checkForFourOfAKind(in hand: [Card]) -> [Meld] {
        var fourOfAKinds: [Meld] = []
        
        // Group cards by value
        let groupedByValue = Dictionary(grouping: hand.filter { !$0.isJoker }) { $0.value }
        
        for (value, cards) in groupedByValue {
            if cards.count >= 4 {
                let meldType: MeldType
                switch value {
                case .jack: meldType = .fourJacks
                case .queen: meldType = .fourQueens
                case .king: meldType = .fourKings
                case .ace: meldType = .fourAces
                default: meldType = .fourOfAKind
                }
                
                fourOfAKinds.append(Meld(cards: Array(cards.prefix(4)), type: meldType))
            }
        }
        
        return fourOfAKinds
    }
} 