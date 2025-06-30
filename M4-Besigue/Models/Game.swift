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
    let gameRules: GameRules
    
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
    
    // Winning card animation state
    @Published var isAnimatingWinningCard: Bool = false
    
    // Draw and play cycle state
    @Published var currentDrawIndex: Int = 0
    @Published var currentPlayIndex: Int = 0
    @Published var hasDrawnForNextTrick: [UUID: Bool] = [:]
    
    // Computed property to check if we're in endgame
    var isEndgame: Bool {
        return deck.isEmpty
    }
    
    init(playerCount: Int = 2, isOnline: Bool = false, aiDifficulty: AIService.Difficulty = .medium, settings: GameSettings = GameSettings()) {
        self.playerCount = playerCount
        self.isOnline = isOnline
        self.deck = Deck()
        self.aiService = AIService(difficulty: aiDifficulty)
        self.settings = settings
        self.gameRules = GameRules()
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
        // Reset brisques
        for player in players {
            brisques[player.id] = 0
        }
        currentTrick.removeAll()
        currentTrickLeader = 0
        trickHistory.removeAll()
        roundNumber = 1
        canPlayerMeld = false
        dealerDeterminationCards.removeAll()
        dealerDeterminedMessage = ""
        jackDrawnForDealer = nil
        showJackProminently = false
        trumpSuit = nil
        isShowingTrickResult = false
        lastTrickWinner = nil
        isPlayingCard = false
        playedCard = nil
        winningCardIndex = nil
        shouldAnimateWinningCard = false
        isAIDrawingCard = false
        aiDrawnCard = nil
        // Set the first player as current player
        currentPlayerIndex = 0
        currentPlayer.isCurrentPlayer = true
        for (index, player) in players.enumerated() {
            if index != currentPlayerIndex {
                player.isCurrentPlayer = false
            }
        }
        // Dealer determination method
        switch gameRules.dealerDeterminationMethod {
        case .random:
            // Pick a random dealer
            let dealerIndex = Int.random(in: 0..<playerCount)
            for (i, player) in players.enumerated() {
                player.isDealer = (i == dealerIndex)
            }
            dealerDeterminedMessage = "Dealer is \(players[dealerIndex].name)! (Random)"
            print("👑 Dealer determined randomly: \(players[dealerIndex].name)")
            // Deal cards and start playing phase
            dealCards()
            currentPhase = .playing
            // The player to the right of the dealer leads the first trick
            currentPlayerIndex = (dealerIndex + 1) % playerCount
            print("🎯 First player: \(currentPlayer.name)")
            if currentPlayer.type == .ai {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.processAITurn()
                }
            }
        case .drawJacks:
            // Use the existing dealer determination phase
            currentPhase = .dealerDetermination
            print("🎯 Dealer determination phase started. Current player: \(currentPlayer.name)")
            if currentPlayer.type == .ai {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.processAIDealerDetermination()
                }
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
        print("🔄 STARTING NEW TRICK:")
        print("   Previous trick leader: \(currentTrickLeader)")
        print("   Current player index: \(currentPlayerIndex)")
        print("   Current player name: \(currentPlayer.name)")
        print("   Current player type: \(currentPlayer.type)")
        
        currentTrick.removeAll()
        currentTrickLeader = currentPlayerIndex
        
        print("   New trick leader set to: \(currentTrickLeader)")
        print("   New trick leader name: \(players[currentTrickLeader].name)")
        
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
        print("🎴 PLAYING CARD:")
        print("   Player: \(player.name) (type: \(player.type))")
        print("   Card: \(card.displayName)")
        print("   Current trick count: \(currentTrick.count)")
        print("   Current trick leader: \(players[currentTrickLeader].name)")
        print("   Current player index: \(currentPlayerIndex)")
        
        // Verify that the player playing the card is the current player
        guard player.id == currentPlayer.id else {
            print("   ❌ ERROR: Player \(player.name) is not the current player \(currentPlayer.name)")
            return
        }
        
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
            
            print("   Card added to trick. New trick count: \(self.currentTrick.count)")
            print("   Current trick cards: \(self.currentTrick.map { $0.displayName })")
            print("   Cards in order: \(self.currentTrick.enumerated().map { "\($0): \($1.displayName) by \(self.players[(self.currentTrickLeader + $0) % self.playerCount].name)" })")
            
            if self.currentTrick.count == self.playerCount {
                print("   🎯 Trick complete, determining winner...")
                self.completeTrick()
            } else {
                print("   ➡️ Moving to next player...")
                self.nextPlayer()
            }
        }
    }
    
    // Complete the current trick
    private func completeTrick() {
        // Determine the winner
        let winnerIndex = determineTrickWinner()
        let winner = players[winnerIndex]
        
        // Determine which card in the trick is the winning card
        let winningCardIndex = determineTrickWinnerIndex() ?? 0
        
        // Show trick winner message
        lastTrickWinner = winner.name
        isShowingTrickResult = true
        
        // Animate winning card moving to top
        isAnimatingWinningCard = true
        self.winningCardIndex = winningCardIndex
        
        // Hide the message and stop animation after configurable delay
        DispatchQueue.main.asyncAfter(deadline: .now() + gameRules.winningCardAnimationDelay) {
            self.isShowingTrickResult = false
            self.lastTrickWinner = nil
            self.isAnimatingWinningCard = false
            self.winningCardIndex = nil
        }
        
        // Add brisques to winner's count
        for card in currentTrick {
            if card.isBrisque {
                brisques[winner.id, default: 0] += 1
            }
        }
        
        // Set up the draw/play cycle for the next trick
        startDrawCycle(trickWinnerIndex: winnerIndex)
        
        // UI/VM should now prompt the player at currentDrawIndex to draw
    }
    
    // Draw card for the current draw turn player
    func drawCardForCurrentDrawTurn() {
        let player = players[currentDrawIndex]
        guard hasDrawnForNextTrick[player.id] == false, !deck.isEmpty else { return }
        if let card = deck.drawCard() {
            player.addCards([card])
            hasDrawnForNextTrick[player.id] = true
        }
        // Advance to next draw turn
        currentDrawIndex = (currentDrawIndex + 1) % playerCount
        // If next is AI, trigger AI draw
        triggerAIDrawIfNeeded()
        // If all have drawn, begin play cycle (UI/VM should prompt currentPlayIndex to play)
    }
    
    // Play card for the current play turn player
    func playCardForCurrentPlayTurn(_ card: PlayerCard) {
        let player = players[currentPlayIndex]
        guard hasDrawnForNextTrick[player.id] == true else { return }
        // Usual play logic here (add card to trick, etc.)
        currentTrick.append(card)
        player.removeCard(card)
        // Advance to next play turn
        currentPlayIndex = (currentPlayIndex + 1) % playerCount
        // If next is AI, trigger AI play
        triggerAIPlayIfNeeded()
        // If all have played, evaluate trick
        if currentTrick.count == playerCount {
            completeTrick()
        }
    }
    
    // Trigger AI draw if it's their turn
    private func triggerAIDrawIfNeeded() {
        let player = players[currentDrawIndex]
        if player.type == .ai && !hasDrawnForNextTrick[player.id, default: false] && !deck.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.drawCardForCurrentDrawTurn()
            }
        }
    }
    
    // Trigger AI play if it's their turn
    private func triggerAIPlayIfNeeded() {
        let player = players[currentPlayIndex]
        if player.type == .ai && hasDrawnForNextTrick[player.id, default: false] {
            let playable = player.getPlayableCards(leadSuit: currentTrick.first?.suit, trumpSuit: trumpSuit)
            if let card = playable.first {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.playCardForCurrentPlayTurn(card)
                }
            }
        }
    }
    
    // Process AI trick winner decision
    private func processAITrickWinner() {
        guard currentPlayer.type == .ai else { return }
        
        print("🤖 AI trick winner processing for \(currentPlayer.name)")
        
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
                
                print("🎬 Starting AI draw animation for \(currentPlayer.name)")
                
                // Start AI draw animation
                isAIDrawingCard = true
                aiDrawnCard = playerCard
                
                // Animate the draw
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    print("🎬 AI draw animation completed, adding card to hand")
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
        print("🔄 Continuing after AI draw")
        
        // Reset meld choice state
        canPlayerMeld = false
        awaitingMeldChoice = false
        mustDrawCard = false
        
        // Start new trick with the same player (trick winner)
        startNewTrick()
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
        print("   Current trick leader index: \(currentTrickLeader)")
        print("   Current trick leader name: \(players[currentTrickLeader].name)")
        print("   Player count: \(playerCount)")
        
        var winningCard = currentTrick[0]
        var winningPlayerIndex = currentTrickLeader
        
        print("   Initial winning card: \(winningCard.displayName) by \(players[winningPlayerIndex].name)")
        
        for (index, card) in currentTrick.enumerated() {
            let playerIndex = (currentTrickLeader + index) % playerCount
            let player = players[playerIndex]
            
            print("   Card \(index + 1): \(card.displayName) by \(player.name) (player index: \(playerIndex))")
            print("   Card details - Suit: \(card.suit?.rawValue ?? "None"), Value: \(card.value?.rawValue ?? "None"), Rank: \(card.rank)")
            print("   Current winning card - Suit: \(winningCard.suit?.rawValue ?? "None"), Value: \(winningCard.value?.rawValue ?? "None"), Rank: \(winningCard.rank)")
            
            if card.canBeat(winningCard, trumpSuit: trumpSuit, leadSuit: currentTrick.first?.suit) {
                print("   ✅ \(card.displayName) BEATS \(winningCard.displayName)")
                winningCard = card
                winningPlayerIndex = playerIndex
                print("   🏆 New winning player: \(players[winningPlayerIndex].name) (index: \(winningPlayerIndex))")
            } else {
                print("   ❌ \(card.displayName) does NOT beat \(winningCard.displayName)")
            }
        }
        
        let winner = players[winningPlayerIndex]
        print("   🏆 FINAL WINNER: \(winner.name) with \(winningCard.displayName)")
        print("   Winner player type: \(winner.type)")
        
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
        
        print("🎯 Getting playable cards for \(currentPlayer.name):")
        print("   Lead suit: \(leadSuit?.rawValue ?? "None")")
        print("   Trump suit: \(trumpSuit?.rawValue ?? "None")")
        print("   All cards in hand: \(currentPlayer.hand.map { $0.displayName })")
        print("   Playable cards: \(playableCards.map { $0.displayName })")
        
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
        
        print("🔍 Validating meld: \(meld.type.name) with \(meld.cards.count) cards")
        print("🔍 Trump suit: \(trumpSuit?.rawValue ?? "None")")
        
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
        
        // Bésigue rules: Before trump suit is established, only common marriages are allowed
        if trumpSuit == nil {
            if meld.type == .commonMarriage {
                print("✅ Common marriage allowed before trump suit establishment")
                return true
            } else {
                print("❌ Only common marriages allowed before trump suit is established")
                return false
            }
        }
        
        // After trump suit is established, all melds are allowed
        print("✅ Trump suit established - all melds allowed")
        
        // Special validation for sequence (requires royal marriage in trump suit)
        if meld.type == .sequence {
            // Check if royal marriage exists for the trump suit
            let hasRoyalMarriage = player.meldsDeclared.contains { meld in
                meld.type == .royalMarriage && meld.cards.first?.suit == trumpSuit
            }
            if !hasRoyalMarriage {
                print("❌ Sequence requires royal marriage in trump suit")
                return false
            }
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
    
    // After a trick ends, reset draw/play cycle state
    private func startDrawCycle(trickWinnerIndex: Int) {
        currentDrawIndex = trickWinnerIndex
        currentPlayIndex = trickWinnerIndex
        for player in players {
            hasDrawnForNextTrick[player.id] = false
        }
    }
} 