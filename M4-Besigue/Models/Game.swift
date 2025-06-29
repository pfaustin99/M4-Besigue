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
    @Published var jackDrawnForDealer: Card? = nil
    @Published var showJackProminently: Bool = false
    
    let settings: GameSettings
    
    // AI Service
    private let aiService: AIService
    
    // Game settings
    let playerCount: Int
    let isOnline: Bool
    
    // Trick result state for UI
    @Published var isShowingTrickResult: Bool = false
    var lastTrickWinner: String? = nil
    
    // Card play animation state
    @Published var isPlayingCard: Bool = false
    @Published var playedCard: PlayerCard? = nil
    @Published var winningCardIndex: Int? = nil
    @Published var shouldAnimateWinningCard: Bool = false
    
    // AI card draw animation state
    @Published var isAIDrawingCard: Bool = false
    @Published var aiDrawnCard: PlayerCard? = nil
    
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
        players.append(Player(name: "Player 1", type: .human))
        
        // Create AI players
        for i in 1..<playerCount {
            players.append(Player(name: "AI-\(i)", type: .ai))
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
        
        // Reset game state and ensure deck is shuffled
        deck.reset()
        deck.shuffle() // Extra shuffle to ensure randomness
        print("🃏 Deck shuffled for dealer determination")
        
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
        jackDrawnForDealer = nil
        showJackProminently = false
        
        // Reset brisques
        for player in players {
            brisques[player.id] = 0
        }
        
        // Start with the first player for dealer determination
        currentPlayerIndex = 0
        
        // Set the first player as current player
        currentPlayer.isCurrentPlayer = true
        
        // Clear other players' current status
        for (index, player) in players.enumerated() {
            if index != currentPlayerIndex {
                player.isCurrentPlayer = false
            }
        }
        
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
        
        // Note: Player transition is now handled in drawCardForDealerDetermination
        // No need to duplicate the logic here
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
        // Start card play animation
        isPlayingCard = true
        playedCard = card
        
        // Animate card play
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isPlayingCard = false
            self.playedCard = nil
            
            // Add card to trick
            self.canPlayerMeld = false
            player.removeCard(card)
            self.currentTrick.append(card)
            
            if self.currentTrick.count == self.playerCount {
                self.completeTrick()
            } else {
                self.nextPlayer()
            }
        }
    }
    
    // Complete the current trick
    private func completeTrick() {
        // Determine the winner
        let winnerIndex = determineTrickWinner()
        let winner = players[winnerIndex]
        
        // Show trick winner message
        lastTrickWinner = winner.name
        isShowingTrickResult = true
        
        // Hide the message after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isShowingTrickResult = false
            self.lastTrickWinner = nil
        }
        
        // Add brisques to winner's count
        for card in currentTrick {
            if card.isBrisque {
                brisques[winner.id, default: 0] += 1
            }
        }
        
        // Set the winner as current player
        currentPlayerIndex = winnerIndex
        
        // Clear previous player's current status
        for (index, player) in players.enumerated() {
            if index != currentPlayerIndex {
                player.isCurrentPlayer = false
            }
        }
        
        // Set the new current player
        currentPlayer.isCurrentPlayer = true
        
        // Check if this is the final trick
        if allPlayersHaveEmptyHands() {
            winner.addPoints(settings.finalTrickBonus)
            endRound()
            return
        }
        
        // If winner is AI, let AI decide on melds and draw
        if currentPlayer.type == .ai {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.processAITrickWinner()
            }
        } else {
            // Human player gets choice to meld first
            canPlayerMeld = true
            awaitingMeldChoice = true
            mustDrawCard = true
        }
        
        // Don't automatically draw cards - winner will draw when they choose to
    }
    
    // Process AI trick winner decision
    private func processAITrickWinner() {
        guard currentPlayer.type == .ai else { return }
        
        // AI decides whether to meld first
        let meldsToDeclare = aiService.decideMeldsToDeclare(for: currentPlayer, in: self)
        if !meldsToDeclare.isEmpty {
            // AI chooses to meld
            for meld in meldsToDeclare {
                declareMeld(meld, by: currentPlayer)
            }
        }
        
        // AI draws a card (if available) with animation
        if !deck.isEmpty {
            if let card = deck.drawCard() {
                let playerCard = PlayerCard(card: card)
                
                // Start AI draw animation
                isAIDrawingCard = true
                aiDrawnCard = playerCard
                
                // Animate the draw
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.currentPlayer.addCards([card])
                    print("🤖 \(self.currentPlayer.name) drew a card")
                    
                    // End animation
                    self.isAIDrawingCard = false
                    self.aiDrawnCard = nil
                    
                    // Continue with game flow
                    self.continueAfterAIDraw()
                }
            } else {
                // No card to draw, continue immediately
                continueAfterAIDraw()
            }
        } else {
            // No cards in deck, continue immediately
            continueAfterAIDraw()
        }
    }
    
    // Continue game flow after AI draw
    private func continueAfterAIDraw() {
        // Reset meld choice state
        canPlayerMeld = false
        awaitingMeldChoice = false
        mustDrawCard = false
        
        // Move to next player for the new trick
        moveToNextPlayer()
        
        // Start new trick
        startNewTrick()
    }
    
    // Move to next player (for when AI wins and we need to let human draw)
    private func moveToNextPlayer() {
        currentPlayerIndex = (currentPlayerIndex + 1) % playerCount
        
        // Update current player status
        for (index, player) in players.enumerated() {
            player.isCurrentPlayer = (index == currentPlayerIndex)
        }
        
        // If next player is human and needs to draw, give them the opportunity
        if currentPlayer.type == .human && !deck.isEmpty {
            mustDrawCard = true
            print("👤 \(currentPlayer.name) can draw a card")
        }
    }
    
    // Human player draws a card (called when they choose to draw)
    func drawCardForCurrentPlayer() {
        guard mustDrawCard else { return }
        
        if !deck.isEmpty {
            if let card = deck.drawCard() {
                currentPlayer.addCards([card])
                print("👤 \(currentPlayer.name) drew a card")
            }
        }
        
        // Reset meld choice state
        canPlayerMeld = false
        awaitingMeldChoice = false
        mustDrawCard = false
        
        // Start new trick
        startNewTrick()
    }
    
    // Determine the winner of the current trick
    private func determineTrickWinner() -> Int {
        guard !currentTrick.isEmpty else { return 0 }
        
        print("🎯 DETERMINING TRICK WINNER:")
        print("   Current trick has \(currentTrick.count) cards")
        print("   Trump suit: \(trumpSuit?.rawValue ?? "None")")
        print("   Lead suit: \(currentTrick.first?.suit?.rawValue ?? "None")")
        
        var winningCard = currentTrick[0]
        var winningPlayerIndex = currentTrickLeader
        
        print("   Initial winning card: \(winningCard.displayName) by \(players[winningPlayerIndex].name)")
        
        for (index, card) in currentTrick.enumerated() {
            let playerIndex = (currentTrickLeader + index) % playerCount
            let player = players[playerIndex]
            
            print("   Card \(index + 1): \(card.displayName) by \(player.name)")
            
            if card.canBeat(winningCard, trumpSuit: trumpSuit, leadSuit: currentTrick.first?.suit) {
                print("   ✅ \(card.displayName) BEATS \(winningCard.displayName)")
                winningCard = card
                winningPlayerIndex = playerIndex
            } else {
                print("   ❌ \(card.displayName) does NOT beat \(winningCard.displayName)")
            }
        }
        
        let winner = players[winningPlayerIndex]
        print("   🏆 WINNER: \(winner.name) with \(winningCard.displayName)")
        
        return winningPlayerIndex
    }
    
    // Determine trick winner index for UI display
    func determineTrickWinnerIndex() -> Int? {
        guard !currentTrick.isEmpty else { return nil }
        
        var winningCard = currentTrick[0]
        var winningIndex = 0
        
        for (index, card) in currentTrick.enumerated() {
            if card.canBeat(winningCard, trumpSuit: trumpSuit, leadSuit: currentTrick.first?.suit) {
                winningCard = card
                winningIndex = index
            }
        }
        
        return winningIndex
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
            print("❌ Meld validation failed: not current player or can't meld")
            return false
        }
        // Only one meld per opportunity
        if player.meldsDeclared.last?.roundNumber == roundNumber {
            print("❌ Meld validation failed: already declared meld this round")
            return false
        }
        if trumpSuit == nil {
            let result = meld.type == .commonMarriage
            print("❓ No trump suit - only common marriage allowed: \(result)")
            return result
        }
        
        print("🔍 Validating meld: \(meld.type.name) with \(meld.cards.count) cards")
        
        // Check if player has all the cards for this meld
        for meldCard in meld.cards {
            let hasCard = player.hand.contains { playerCard in
                // Compare the actual card properties instead of IDs
                playerCard.suit == meldCard.suit && 
                playerCard.value == meldCard.value &&
                playerCard.isJoker == meldCard.isJoker
            }
            if !hasCard {
                print("❌ Missing card for meld: \(meldCard.displayName)")
                return false
            }
        }
        
        // Check if this meld type has already been declared
        let alreadyDeclared = player.meldsDeclared.contains { $0.type == meld.type }
        if alreadyDeclared {
            print("❌ Meld type \(meld.type.name) already declared")
            return false
        }
        
        print("✅ Meld validation successful")
        return true
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
                print("🎯 JACK DRAWN! Setting jackDrawnForDealer to \(card.imageName)")
                jackDrawnForDealer = card
                showJackProminently = true
                let dealerIndex = (dealerDeterminationCards.count - 1) % playerCount
                for (i, player) in players.enumerated() {
                    player.isDealer = (i == dealerIndex)
                }
                
                // Set dealer message
                let dealer = players[dealerIndex]
                dealerDeterminedMessage = "Dealer is \(dealer.name)!"
                print("👑 Dealer determined: \(dealer.name)")
                print("📝 Dealer message: \(dealerDeterminedMessage)")
                
                // Keep dealer determination phase active for configurable delay
                print("⏸️ Keeping dealer determination visible for \(settings.dealerDeterminationDelay) seconds...")
                DispatchQueue.main.asyncAfter(deadline: .now() + settings.dealerDeterminationDelay) {
                    print("⏰ \(self.settings.dealerDeterminationDelay) seconds passed, completing dealer determination")
                    self.showJackProminently = false
                    self.completeDealerDetermination()
                }
                
                return // Don't continue to next player
            } else {
                print("🔄 No Jack drawn, continuing dealer determination...")
                // Move to next player for dealer determination
                currentPlayerIndex = (currentPlayerIndex + 1) % playerCount
                currentPlayer.isCurrentPlayer = true
                
                // Clear previous player's current status
                for (index, player) in players.enumerated() {
                    if index != currentPlayerIndex {
                        player.isCurrentPlayer = false
                    }
                }
                
                print("🔄 Moving to next player: \(currentPlayer.name)")
                
                // If next player is AI, continue the process
                if currentPlayer.type == .ai {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.processAIDealerDetermination()
                    }
                }
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
        jackDrawnForDealer = nil
        
        // Deal cards
        dealCards()
        
        // Trump suit is NOT set here - it will be determined by the first royal marriage
        // (King + Queen of the same suit) that is declared during play
        trumpSuit = nil
        print("🃏 Trump suit will be determined by the first royal marriage declared")
        
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
    
    func playInvalidMeldAnimation() {
        // Stub: No-op for now, can be used to trigger UI feedback
    }
    
    // Animate winning card display
    func animateWinningCard() {
        guard let winningIndex = determineTrickWinnerIndex() else { return }
        
        winningCardIndex = winningIndex
        
        // Delay before showing winning card (configurable)
        DispatchQueue.main.asyncAfter(deadline: .now() + settings.cardPlayDelay.rawValue) {
            self.shouldAnimateWinningCard = true
            
            // Reset after animation duration
            DispatchQueue.main.asyncAfter(deadline: .now() + self.settings.cardPlayDuration.rawValue) {
                self.shouldAnimateWinningCard = false
                self.winningCardIndex = nil
            }
        }
    }
} 