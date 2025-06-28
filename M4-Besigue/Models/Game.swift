import Foundation

// MARK: - Game Phase
enum GamePhase {
    case setup
    case dealing
    case dealerDetermination // Added for dealer selection phase
    case playing
    case endgame // No more cards to draw, stricter rules
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
    @Published var currentTrick: [PlayerCard] = []
    @Published var currentTrickLeader: Int = 0
    @Published var trickHistory: [[PlayerCard]] = []
    @Published var roundNumber: Int = 1
    @Published var gameNumber: Int = 1
    @Published var canPlayerMeld: Bool = false
    @Published var brisques: [UUID: Int] = [:] // Track brisques per player
    
    // Dealer determination state
    @Published var dealerDeterminationCards: [Card] = []
    @Published var dealerDeterminedMessage: String = ""
    @Published var awaitingMeldChoice: Bool = false
    @Published var mustDrawCard: Bool = false
    
    let settings: GameSettings
    
    // AI Service
    private let aiService: AIService
    
    // Game settings
    let playerCount: Int
    let isOnline: Bool
    
    // Trick result state for UI
    @Published var isShowingTrickResult: Bool = false
    var lastTrickWinner: String? = nil
    
    // Computed property to check if we're in endgame
    var isEndgame: Bool {
        return deck.isEmpty
    }
    
    init(playerCount: Int = 2, isOnline: Bool = false, aiDifficulty: AIService.Difficulty = .medium, settings: GameSettings = GameSettings(playerCount: 2)) {
        self.playerCount = playerCount
        self.isOnline = isOnline
        self.deck = Deck()
        self.aiService = AIService(difficulty: aiDifficulty)
        self.settings = settings
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
        
        // Initialize brisques for each player
        for player in players {
            brisques[player.id] = 0
        }
    }
    
    // Start a new game
    func startNewGame() {
        print("🎮 Starting new game...")
        
        // Reset all players
        for player in players {
            player.reset()
        }
        
        // Reset game state
        deck.reset()
        currentPhase = .dealerDetermination
        currentPlayerIndex = 0
        trumpSuit = nil
        currentTrick.removeAll()
        currentTrickLeader = 0
        trickHistory.removeAll()
        roundNumber = 1
        canPlayerMeld = false
        dealerDeterminationCards.removeAll()
        dealerDeterminedMessage = ""
        
        // Reset brisques
        for player in players {
            brisques[player.id] = 0
        }
        
        // Start with the first player for dealer determination
        currentPlayerIndex = 0
        
        print("🎯 Dealer determination phase started. Current player: \(currentPlayer.name)")
        
        // If AI is first, start the dealer determination process
        if currentPlayer.type == .ai {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.processAIDealerDetermination()
            }
        }
    }
    
    // Process AI dealer determination
    private func processAIDealerDetermination() {
        guard currentPhase == .dealerDetermination && currentPlayer.type == .ai else { return }
        
        print("🤖 AI player \(currentPlayer.name) is drawing for dealer determination...")
        
        // AI draws a card for dealer determination
        drawCardForDealerDetermination()
        
        // If dealer is not yet determined, continue to next player
        if currentPhase == .dealerDetermination {
            // Move to next player
            currentPlayerIndex = (currentPlayerIndex + 1) % playerCount
            currentPlayer.isCurrentPlayer = true
            
            // Clear previous player's current status
            for (index, player) in players.enumerated() {
                if index != currentPlayerIndex {
                    player.isCurrentPlayer = false
                }
            }
            
            print("🔄 Moving to next player: \(currentPlayer.name)")
            
            // If next player is also AI, continue the process
            if currentPlayer.type == .ai {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.processAIDealerDetermination()
                }
            }
        }
    }
    
    // Deal cards to all players
    private func dealCards() {
        print("🃏 Dealing cards to \(playerCount) players...")
        let playerHands = deck.dealCards(to: playerCount)
        
        for (index, hand) in playerHands.enumerated() {
            players[index].addCards(hand)
            print("👤 \(players[index].name) received \(hand.count) cards")
        }
        
        print("✅ Dealt \(playerHands[0].count) cards to each player")
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
        
        // Process AI turn if it's an AI player's turn
        if currentPlayer.type == .ai {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.processAITurn()
            }
        }
    }
    
    // Process AI turn
    private func processAITurn() {
        guard currentPlayer.type == .ai else { return }
        
        // If AI can meld (it just won a trick), it decides on melds first.
        if canPlayerMeld {
            let meldsToDeclare = aiService.decideMeldsToDeclare(for: currentPlayer, in: self)
            for meld in meldsToDeclare {
                declareMeld(meld, by: currentPlayer)
            }
        }
        
        // AI then plays a card
        if let cardToPlay = aiService.chooseCardToPlay(for: currentPlayer, in: self) {
            playCard(cardToPlay, from: currentPlayer)
        }
    }
    
    // Start a new trick
    func startNewTrick() {
        currentTrick.removeAll()
        currentTrickLeader = currentPlayerIndex
        currentPhase = .playing
        
        // If AI is leading, make AI decision
        if currentPlayer.type == .ai {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.processAITurn()
            }
        }
    }
    
    // Play a card
    func playCard(_ card: PlayerCard, from player: Player) {
        canPlayerMeld = false
        player.removeCard(card)
        currentTrick.append(card)
        if currentTrick.count == playerCount {
            completeTrick()
        } else {
            nextPlayer()
        }
    }
    
    // Complete the current trick
    private func completeTrick() {
        let winnerIndex = determineTrickWinner()
        let winner = players[winnerIndex]
        // Track brisques (Aces and 10s)
        for card in currentTrick {
            if card.value == .ace || card.value == .ten {
                brisques[winner.id, default: 0] += 1
            }
        }
        trickHistory.append(currentTrick)
        currentPlayerIndex = winnerIndex
        
        // Check if we should transition to endgame
        if deck.isEmpty && currentPhase == .playing {
            currentPhase = .endgame
            print("Endgame phase: No more cards to draw, stricter rules in effect")
        }
        
        // In endgame, no more melds allowed
        canPlayerMeld = currentPhase != .endgame
        
        // Winner and then other players draw cards (only if not in endgame)
        if !deck.isEmpty {
            for i in 0..<playerCount {
                let playerIndexToDraw = (winnerIndex + i) % playerCount
                if let card = deck.drawCard() {
                    players[playerIndexToDraw].addCards([card])
                }
            }
        }
        currentTrick.removeAll()
        if allPlayersHaveEmptyHands() {
            // Award final trick bonus before scoring
            winner.addPoints(settings.finalTrickBonus)
            endRound()
        } else {
            if currentPlayer.type == .ai {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.processAITurn()
                }
            }
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
        calculateFinalScores()
        if hasWinner() {
            currentPhase = .gameOver
        } else {
            roundNumber += 1
            startNewGame()
        }
    }
    
    // Calculate final scores for the round
    private func calculateFinalScores() {
        // Brisques scoring
        let brisqueCutoffReached = players.contains { $0.totalPoints >= settings.brisqueCutoff }
        for player in players {
            let brisqueCount = brisques[player.id, default: 0]
            var eligible = true
            if brisqueCutoffReached {
                eligible = false
            } else if brisqueCount < settings.minBrisques {
                eligible = false
            } else if player.totalPoints < settings.minScoreForBrisques {
                eligible = false
            }
            if eligible {
                player.addPoints(brisqueCount * settings.brisqueValue)
            } else {
                player.addPoints(settings.penalty)
            }
        }
        // Print scores for debugging
        for player in players {
            print("\(player.name): \(player.totalPoints) points (Brisques: \(brisques[player.id, default: 0]))")
        }
    }
    
    // Check if there's a winner
    private func hasWinner() -> Bool {
        return players.contains { $0.totalPoints >= settings.winningScore }
    }
    
    // Get the winner
    var winner: Player? {
        return players.first { $0.totalPoints >= settings.winningScore }
    }
    
    // Set trump suit
    func setTrumpSuit(_ suit: Suit) {
        trumpSuit = suit
    }
    
    // Get playable cards for current player
    func getPlayableCards() -> [PlayerCard] {
        let leadSuit = currentTrick.first?.suit
        let playableCards = currentPlayer.getPlayableCards(leadSuit: leadSuit, trumpSuit: trumpSuit)
        
        // In endgame, enforce stricter rules
        if isEndgame {
            return getEndgamePlayableCards(leadSuit: leadSuit, trumpSuit: trumpSuit, allCards: playableCards)
        }
        
        return playableCards
    }
    
    // Get playable cards with endgame rules
    private func getEndgamePlayableCards(leadSuit: Suit?, trumpSuit: Suit?, allCards: [PlayerCard]) -> [PlayerCard] {
        guard let leadSuit = leadSuit else {
            return allCards // Leading, can play any card
        }
        
        let canFollowSuit = currentPlayer.canFollowSuit(leadSuit: leadSuit)
        
        if canFollowSuit {
            // Must follow suit and play higher if possible
            let suitCards = currentPlayer.cardsOfSuit(leadSuit)
            let currentWinningCard = findCurrentWinningCard(leadSuit: leadSuit, trumpSuit: trumpSuit)
            
            if let winningCard = currentWinningCard {
                // Must play higher if possible
                let higherCards = suitCards.filter { $0.canBeat(winningCard, trumpSuit: trumpSuit, leadSuit: leadSuit) }
                return higherCards.isEmpty ? suitCards : higherCards
            } else {
                return suitCards
            }
        } else {
            // Can't follow suit, must trump if possible
            if let trumpSuit = trumpSuit {
                let trumpCards = currentPlayer.cardsOfSuit(trumpSuit)
                if !trumpCards.isEmpty {
                    return trumpCards
                }
            }
            // No trump cards, can play any card
            return allCards
        }
    }
    
    // Find current winning card in the trick
    private func findCurrentWinningCard(leadSuit: Suit, trumpSuit: Suit?) -> PlayerCard? {
        guard !currentTrick.isEmpty else { return nil }
        
        var winningCard = currentTrick[0]
        
        for card in currentTrick {
            if card.canBeat(winningCard, trumpSuit: trumpSuit, leadSuit: leadSuit) {
                winningCard = card
            }
        }
        
        return winningCard
    }
    
    // Check if a meld can be declared
    func canDeclareMeld(_ meld: Meld, by player: Player) -> Bool {
        guard player.id == currentPlayer.id && canPlayerMeld else {
            return false
        }
        // Only one meld per opportunity
        if player.meldsDeclared.last?.roundNumber == roundNumber {
            return false
        }
        if trumpSuit == nil {
            return meld.type == .commonMarriage
        }
        for card in meld.cards {
            if !player.hasCard(card) {
                return false
            }
        }
        return !player.meldsDeclared.contains { $0.type == meld.type }
    }
    
    // Declare a meld
    func declareMeld(_ meld: Meld, by player: Player) {
        if canDeclareMeld(meld, by: player) {
            var finalMeld = meld
            
            // If this is the first marriage, it sets the trump suit and becomes a Royal Marriage
            if trumpSuit == nil, meld.type == .commonMarriage {
                trumpSuit = meld.cards.first?.suit
                finalMeld = Meld(cards: meld.cards, type: .royalMarriage, pointValue: settings.royalMarriagePoints, roundNumber: self.roundNumber)
                print("Trump suit set to \(trumpSuit?.rawValue ?? "")")
            } else if meld.type == .commonMarriage, let trump = trumpSuit, meld.cards.first?.suit == trump {
                // This is a marriage in the trump suit, so it's a Royal Marriage
                finalMeld = Meld(cards: meld.cards, type: .royalMarriage, pointValue: settings.royalMarriagePoints, roundNumber: self.roundNumber)
            }
            
            player.declareMeld(finalMeld)
            print("\(player.name) declared \(finalMeld.type.name) for \(finalMeld.pointValue) points")
            
            // Handle point doubling for four-of-a-kind in trump suit
            if let trump = trumpSuit {
                let isTrumpMeld = finalMeld.cards.allSatisfy { $0.suit == trump }
                if isTrumpMeld {
                    switch finalMeld.type {
                    case .fourAces, .fourKings, .fourQueens, .fourJacks:
                        // player.declareMeld already added points once, so just add them again to double.
                        player.addPoints(finalMeld.pointValue)
                        print("Doubled points for \(finalMeld.type.name) in trump suit!")
                    default:
                        break
                    }
                }
            }
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
        
        // Check for four jokers
        if let fourJokersMeld = checkForFourJokers(in: player.hand) {
            possibleMelds.append(fourJokersMeld)
        }
        
        // Check for sequence
        if let sequenceMeld = checkForSequence(in: player.hand) {
            possibleMelds.append(sequenceMeld)
        }
        
        return possibleMelds
    }
    
    // Check for Bésigue meld
    private func checkForBesigue(in hand: [PlayerCard]) -> Meld? {
        let queenOfSpades = hand.first { $0.suit == .spades && $0.value == .queen && !$0.usedInMeldTypes.contains(.besigue) }
        let jackOfDiamonds = hand.first { $0.suit == .diamonds && $0.value == .jack && !$0.usedInMeldTypes.contains(.besigue) }
        
        if let queen = queenOfSpades, let jack = jackOfDiamonds {
            return Meld(cards: [queen, jack], type: .besigue, pointValue: settings.besiguePoints, roundNumber: self.roundNumber)
        }
        
        return nil
    }
    
    // Check for marriage melds
    private func checkForMarriages(in hand: [PlayerCard]) -> [Meld] {
        var marriages: [Meld] = []
        
        for suit in Suit.allCases {
            let king = hand.first { $0.suit == suit && $0.value == .king && !$0.usedInMeldTypes.contains(.commonMarriage) && !$0.usedInMeldTypes.contains(.royalMarriage) }
            let queen = hand.first { $0.suit == suit && $0.value == .queen && !$0.usedInMeldTypes.contains(.commonMarriage) && !$0.usedInMeldTypes.contains(.royalMarriage) }
            
            if let king = king, let queen = queen {
                let meldType: MeldType = .commonMarriage
                let points = (trumpSuit != nil && suit == trumpSuit) ? settings.royalMarriagePoints : settings.commonMarriagePoints
                marriages.append(Meld(cards: [king, queen], type: meldType, pointValue: points, roundNumber: self.roundNumber))
            }
        }
        
        return marriages
    }
    
    // Check for four of a kind melds
    private func checkForFourOfAKind(in hand: [PlayerCard]) -> [Meld] {
        var fourOfAKinds: [Meld] = []
        
        let groupedByValue = Dictionary(grouping: hand.filter { !$0.isJoker }) { $0.value }
        
        for (value, cards) in groupedByValue {
            let unusedCards = cards.filter { card in
                switch value {
                case .jack: return !card.usedInMeldTypes.contains(.fourJacks)
                case .queen: return !card.usedInMeldTypes.contains(.fourQueens)
                case .king: return !card.usedInMeldTypes.contains(.fourKings)
                case .ace: return !card.usedInMeldTypes.contains(.fourAces)
                default: return false
                }
            }
            if unusedCards.count >= 4 {
                let meldType: MeldType
                let points: Int
                switch value {
                case .jack: meldType = .fourJacks; points = settings.fourJacksPoints
                case .queen: meldType = .fourQueens; points = settings.fourQueensPoints
                case .king: meldType = .fourKings; points = settings.fourKingsPoints
                case .ace: meldType = .fourAces; points = settings.fourAcesPoints
                default: continue
                }
                fourOfAKinds.append(Meld(cards: Array(unusedCards.prefix(4)), type: meldType, pointValue: points, roundNumber: self.roundNumber))
            }
        }
        
        return fourOfAKinds
    }
    
    // Check for four jokers
    private func checkForFourJokers(in hand: [PlayerCard]) -> Meld? {
        let jokers = hand.filter { $0.isJoker && !$0.usedInMeldTypes.contains(.fourJokers) }
        if jokers.count == 4 {
            return Meld(cards: Array(jokers.prefix(4)), type: .fourJokers, pointValue: settings.fourJokersPoints, roundNumber: self.roundNumber)
        }
        return nil
    }
    
    // Check for sequence in trump suit
    private func checkForSequence(in hand: [PlayerCard]) -> Meld? {
        guard let trumpSuit = trumpSuit else { return nil }
        
        let requiredValues: [CardValue] = [.ace, .ten, .king, .queen, .jack]
        var sequenceCards: [PlayerCard] = []
        
        for value in requiredValues {
            if let card = hand.first(where: { $0.suit == trumpSuit && $0.value == value && !$0.usedInMeldTypes.contains(.sequence) }) {
                sequenceCards.append(card)
            } else {
                return nil // Missing a card for the sequence
            }
        }
        
        if sequenceCards.count == requiredValues.count {
            // Ensure royal marriage is present and intact
            let hasRoyalMarriage = hand.contains(where: { $0.suit == trumpSuit && $0.value == .king && $0.usedInMeldTypes.contains(.royalMarriage) }) &&
                                   hand.contains(where: { $0.suit == trumpSuit && $0.value == .queen && $0.usedInMeldTypes.contains(.royalMarriage) })
            if hasRoyalMarriage {
                return Meld(cards: sequenceCards, type: .sequence, pointValue: settings.sequencePoints, roundNumber: self.roundNumber)
            }
        }
        
        return nil
    }
    
    var dealerDetermined: Bool {
        return currentPhase != .dealerDetermination
    }
    
    func canPlayCard() -> Bool {
        // Player can play if not awaiting meld choice, not in dealer determination, and not required to draw
        return !awaitingMeldChoice && !mustDrawCard && currentPhase == .playing
    }
    
    // Draw card for dealer determination phase
    func drawCardForDealerDetermination() {
        guard currentPhase == .dealerDetermination else { 
            print("❌ Not in dealer determination phase")
            return 
        }
        
        if let card = deck.drawCard() {
            print("🎴 \(currentPlayer.name) draws \(card.imageName) for dealer determination")
            dealerDeterminationCards.append(card)
            
            // If a Jack is drawn, set dealer and show message
            if !card.isJoker && card.value == .jack {
                let dealerIndex = (dealerDeterminationCards.count - 1) % playerCount
                for (i, player) in players.enumerated() {
                    player.isDealer = (i == dealerIndex)
                }
                dealerDeterminedMessage = "Dealer is \(players[dealerIndex].name)!"
                print("👑 Dealer determined: \(players[dealerIndex].name)")
                
                // Move to dealing phase but keep cards visible
                currentPhase = .dealing
                print("🃏 Moving to dealing phase...")
                
                // Start dealing process after a delay to show the dealer message
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.completeDealerDetermination()
                }
            } else {
                print("🔄 No Jack drawn, continuing dealer determination...")
            }
        } else {
            print("❌ No cards left in deck for dealer determination")
        }
    }
    
    // Complete the dealer determination process
    private func completeDealerDetermination() {
        // Return drawn cards to deck and shuffle
        deck.cards.append(contentsOf: dealerDeterminationCards)
        deck.shuffle()
        dealerDeterminationCards.removeAll()
        
        // Deal cards
        dealCards()
        
        // Set trump suit (first card of the deck after dealing)
        if let trumpCard = deck.drawCard() {
            trumpSuit = trumpCard.suit
            // Put the trump card back on top of the deck
            deck.cards.insert(trumpCard, at: 0)
            print("🎯 Trump suit set to: \(trumpSuit?.rawValue.capitalized ?? "None")")
        }
        
        // Move to playing phase
        currentPhase = .playing
        print("🎮 Moving to playing phase...")
        
        // Find the dealer index
        let dealerIndex = players.firstIndex(where: { $0.isDealer }) ?? 0
        
        // The player to the right of the dealer leads the first trick
        currentPlayerIndex = (dealerIndex + 1) % playerCount
        print("🎯 First player: \(currentPlayer.name)")
        
        // Start AI turn if AI is first
        if currentPlayer.type == .ai {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.processAITurn()
            }
        }
    }
    
    func determineTrickWinnerIndex() -> Int? {
        // Stub: Return the winner index of the last trick if available
        // You can implement actual logic later
        if let last = trickHistory.last, !last.isEmpty {
            // Find the player who won the last trick
            let winnerIndex = determineTrickWinner()
            return winnerIndex
        }
        return nil
    }
    
    func playInvalidMeldAnimation() {
        // Stub: No-op for now, can be used to trigger UI feedback
    }
    
    func drawCardForCurrentPlayer() {
        // Stub: Draw a card for the current player if possible
        if let card = deck.drawCard() {
            currentPlayer.addCards([card])
            mustDrawCard = false
        }
    }
} 