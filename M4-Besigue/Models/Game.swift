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
    
    // Tiebreaker state
    @Published var isInTiebreaker: Bool = false
    @Published var tiebreakerPlayers: [Player] = []
    @Published var tiebreakerCards: [Card] = []
    @Published var tiebreakerMessage: String = ""
    
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
    
    // Draw/Play cycle state
    @Published var currentDrawIndex: Int = 0
    @Published var currentPlayIndex: Int = 0
    @Published var hasDrawnForNextTrick: [UUID: Bool] = [:]
    @Published var isDrawCycle: Bool = true
    
    // Endgame state
    @Published var isEndgame: Bool = false
    
    // MARK: - Game State
    @Published var isFirstTrick: Bool = true  // Track if we're still in the first trick
    
    // MARK: - Automated Test Functions
    
    // Test configuration
    var isUnrestrictedMode: Bool = false
    var skipTrickEvaluationDelay: Bool = false
    
    // MARK: - Test Case 1: First Trick Flow (No Delay)
    func testFirstTrickFlow() -> Bool {
        print("🧪 TEST CASE 1: First Trick Flow")
        
        // Setup
        startNewGame()
        let player1 = players[0]
        let player2 = players[1]
        
        // Verify initial state
        guard player1.hand.count == 9 && player2.hand.count == 9 else {
            print("❌ FAIL: Players don't have 9 cards each")
            return false
        }
        
        // Player 1 plays first card
        let card1 = player1.hand[0]
        playCard(card1, from: player1)
        
        // Verify card is in trick
        guard currentTrick.count == 1 else {
            print("❌ FAIL: Card not added to trick")
            return false
        }
        
        // Player 2 plays second card
        let card2 = player2.hand[0]
        playCard(card2, from: player2)
        
        // Verify both cards are in trick
        guard currentTrick.count == 2 else {
            print("❌ FAIL: Second card not added to trick")
            return false
        }
        
        // In unrestricted mode, skip evaluation delay
        if isUnrestrictedMode || skipTrickEvaluationDelay {
            // Immediately finalize trick completion
            finalizeTrickCompletion(winner: players[determineTrickWinner()])
        }
        
        // Verify winner can take action
        guard canPlayerMeld else {
            print("❌ FAIL: Winner cannot meld")
            return false
        }
        
        print("✅ PASS: First trick flow works correctly")
        return true
    }
    
    // MARK: - Test Case 2: Drawing Functionality
    func testDrawingFunctionality() -> Bool {
        print("🧪 TEST CASE 2: Drawing Functionality")
        
        // Setup: Complete first trick
        _ = testFirstTrickFlow()
        
        let winner = players[determineTrickWinner()]
        let initialDeckSize = deck.cards.count
        
        // Winner draws a card
        drawCardForCurrentPlayer()
        
        // Verify card was drawn
        guard winner.hand.count > 0 else {
            print("❌ FAIL: Winner didn't draw a card")
            return false
        }
        
        // Verify deck size decreased
        guard deck.cards.count == initialDeckSize - 1 else {
            print("❌ FAIL: Deck size didn't decrease")
            return false
        }
        
        // Verify new trick started
        guard mustDrawCard else {
            print("❌ FAIL: New trick didn't start")
            return false
        }
        
        print("✅ PASS: Drawing functionality works correctly")
        return true
    }
    
    // MARK: - Test Case 4: Melding + Drawing
    func testMeldingAndDrawing() -> Bool {
        print("🧪 TEST CASE 4: Melding + Drawing")
        
        // Setup: Complete first trick
        _ = testFirstTrickFlow()
        
        let winner = players[determineTrickWinner()]
        let initialPoints = winner.totalPoints
        
        // Create a simple meld (if possible)
        if let meld = createTestMeld(for: winner) {
            // Declare meld
            declareMeld(meld, by: winner)
            
            // Verify points increased
            guard winner.totalPoints > initialPoints else {
                print("❌ FAIL: Points didn't increase after meld")
                return false
            }
            
            // Verify winner can still draw
            let initialHandSize = winner.hand.count
            drawCardForCurrentPlayer()
            
            guard winner.hand.count > initialHandSize else {
                print("❌ FAIL: Winner couldn't draw after melding")
                return false
            }
            
            print("✅ PASS: Melding + Drawing works correctly")
            return true
        } else {
            print("⚠️ SKIP: No valid meld available for testing")
            return true
        }
    }
    
    // MARK: - Test Case 5: Unrestricted Mode
    func testUnrestrictedMode() -> Bool {
        print("🧪 TEST CASE 5: Unrestricted Mode")
        
        // Enable unrestricted mode
        isUnrestrictedMode = true
        skipTrickEvaluationDelay = true
        
        // Test that players can play without restrictions
        startNewGame()
        
        let player1 = players[0]
        let player2 = players[1]
        
        // Players should be able to play immediately
        let card1 = player1.hand[0]
        playCard(card1, from: player1)
        
        let card2 = player2.hand[0]
        playCard(card2, from: player2)
        
        // In unrestricted mode, no drawing should be required
        guard !mustDrawCard else {
            print("❌ FAIL: Drawing still required in unrestricted mode")
            return false
        }
        
        print("✅ PASS: Unrestricted mode works correctly")
        return true
    }
    
    // MARK: - Helper Functions for Tests
    
    private func createTestMeld(for player: Player) -> Meld? {
        // Look for any valid meld in player's hand
        let possibleMelds = getPossibleMelds(for: player)
        return possibleMelds.first
    }
    
    // MARK: - Run All Tests
    func runAllTests() {
        print("🧪 RUNNING ALL AUTOMATED TESTS")
        print("==================================")
        
        var passedTests = 0
        var totalTests = 0
        
        // Test Case 1
        totalTests += 1
        if testFirstTrickFlow() {
            passedTests += 1
        }
        
        // Test Case 2
        totalTests += 1
        if testDrawingFunctionality() {
            passedTests += 1
        }
        
        // Test Case 4
        totalTests += 1
        if testMeldingAndDrawing() {
            passedTests += 1
        }
        
        // Test Case 5
        totalTests += 1
        if testUnrestrictedMode() {
            passedTests += 1
        }
        
        print("==================================")
        print("🧪 TEST RESULTS: \(passedTests)/\(totalTests) tests passed")
        
        if passedTests == totalTests {
            print("🎉 ALL TESTS PASSED!")
        } else {
            print("❌ SOME TESTS FAILED - Check implementation")
        }
    }
    
    // MARK: - Unrestricted Mode Functions
    
    func enableUnrestrictedMode() {
        isUnrestrictedMode = true
        skipTrickEvaluationDelay = true
        print("🎮 Unrestricted mode enabled - No drawing restrictions, no evaluation delays")
    }
    
    func disableUnrestrictedMode() {
        isUnrestrictedMode = false
        skipTrickEvaluationDelay = false
        print("🎮 Unrestricted mode disabled - Normal game rules apply")
    }
    
    // Override drawing requirements in unrestricted mode
    func canPlayCardUnrestricted() -> Bool {
        if isUnrestrictedMode {
            return currentTrick.count < playerCount
        } else {
            return canPlayCard()
        }
    }
    
    init(gameRules: GameRules, isOnline: Bool = false) {
        self.gameRules = gameRules
        self.settings = GameSettings()
        self.playerCount = gameRules.playerCount
        self.isOnline = isOnline
        self.deck = Deck()
        self.aiService = AIService(difficulty: .medium)
        
        // Create players based on configuration
        createPlayersFromConfiguration()
    }
    
    // MARK: - Player Creation
    
    private func createPlayersFromConfiguration() {
        players.removeAll()
        
        print("🎮 Creating players from configuration...")
        print("   Total configurations: \(gameRules.playerConfigurations.count)")
        
        for config in gameRules.playerConfigurations.sorted(by: { $0.position < $1.position }) {
            let playerType: PlayerType = config.type == .human ? .human : .ai
            let player = Player(name: config.name, type: playerType)
            players.append(player)
            print("   Created player: \(player.name) (\(player.type)) at position \(config.position)")
        }
        
        // Safety check - ensure we have at least one player
        if players.isEmpty {
            print("⚠️  No players created! Creating default players...")
            // Create default players as fallback
            players.append(Player(name: "You", type: .human))
            players.append(Player(name: "Port-au-Prince (AI)", type: .ai))
        }
        
        print("🎮 Created \(players.count) players:")
        for (index, player) in players.enumerated() {
            print("   \(index): \(player.name) (\(player.type))")
        }
    }
    
    // Start a new game
    func startNewGame() {
        print("🎮 Starting new game...")
        
        // Update players from current configuration
        updatePlayersFromConfiguration()
        
        // Reset all players
        for player in players {
            player.reset()
        }
        
        // Reset all game state
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
        isInTiebreaker = false
        tiebreakerPlayers.removeAll()
        tiebreakerCards.removeAll()
        tiebreakerMessage = ""
        isEndgame = false
        isDrawCycle = true
        currentDrawIndex = 0
        currentPlayIndex = 0
        currentPlayerIndex = 0
        currentPhase = .playing
        
        // Reset deck
        deck = Deck()
        deck.shuffle()
        
        // Deal cards
        dealInitialCards()
        
        // After dealing cards, set up for first trick
        currentTrick.removeAll()
        currentTrickLeader = 0
        currentPlayerIndex = 0
        currentDrawIndex = 0
        currentPlayIndex = 0
        mustDrawCard = false // <-- Fix: Do NOT require draw after deal
        for player in players {
            hasDrawnForNextTrick[player.id] = false
        }
        
        // Check endgame state
        checkEndgame()
        
        print("🎮 New game started with \(players.count) players")
    }
    
    // Update players when game rules change
    func updatePlayersFromConfiguration() {
        let configurations = gameRules.playerConfigurations
        players = configurations.map { config in
            let player = Player(
                name: config.name,
                type: config.type
            )
            return player
        }
        print("👥 Created \(players.count) players from configuration")
    }
    
    // Determine dealer based on game rules
    func determineDealer() {
        switch gameRules.dealerDeterminationMethod {
        case .random:
            // Pick a random dealer
            let dealerIndex = Int.random(in: 0..<players.count)
            for (i, player) in players.enumerated() {
                player.isDealer = (i == dealerIndex)
                player.isCurrentPlayer = false // Reset all players
            }
            dealerDeterminedMessage = "Dealer is \(players[dealerIndex].name)! (Random)"
            print("👑 Dealer determined randomly: \(players[dealerIndex].name)")
            
            // The player to the right of the dealer leads the first trick
            currentPlayerIndex = (dealerIndex + 1) % players.count
            currentTrickLeader = currentPlayerIndex
            currentPlayer.isCurrentPlayer = true // Set the first player as current
            print("🎯 First player: \(currentPlayer.name)")
            
            // FIX: Set phase to playing after random dealer determination
            currentPhase = .playing
            
        case .drawJacks:
            // Use the existing dealer determination phase
            currentPhase = .dealerDetermination
            print("🎯 Dealer determination phase started. Current player: \(currentPlayer.name)")
        }
    }
    
    // Deal initial cards to all players
    func dealInitialCards() {
        // Deal 9 cards to each player
        for _ in 0..<9 {
            for player in players {
                if let card = deck.drawCard() {
                    let playerCard = PlayerCard(card: card)
                    player.hand.append(playerCard)
                }
            }
        }
        
        print("🎴 Dealt 9 cards to each of \(players.count) players")
        print("🃏 Deck has \(deck.cards.count) cards remaining")
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
    func processAITurn() {
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
        
        // Set up draw cycle for the new trick
        currentDrawIndex = currentTrickLeader
        currentPlayIndex = currentTrickLeader
        isDrawCycle = true
        mustDrawCard = true
        
        // Reset draw status for all players
        for player in players {
            hasDrawnForNextTrick[player.id] = false
        }
        
        print("🔄 Draw cycle initialized - \(currentPlayer.name) can draw a card")
        print("🔄 Must draw card: \(mustDrawCard)")
        
        // If AI is leading, make AI decision
        if currentPlayer.type == .ai {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.processAITurn()
            }
        }
    }
    
    // Play a card (synchronous version for testing)
    func playCardSync(_ card: PlayerCard, from player: Player) {
        print("🎴 PLAYING CARD (SYNC):")
        print("   Player: \(player.name) (type: \(player.type))")
        print("   Card: \(card.displayName)")
        
        // Add card to trick immediately
        player.removeCard(card)
        currentTrick.append(card)
        
        print("   Card added to trick. New trick count: \(currentTrick.count)")
        print("   Current trick cards: \(currentTrick.map { $0.displayName })")
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
        print("🎯 COMPLETING TRICK - Starting evaluation flow")
        
        // Determine the winner
        let winnerIndex = determineTrickWinner()
        let winner = players[winnerIndex]
        
        // Determine which card in the trick is the winning card
        let winningCardIndex = determineTrickWinnerIndex() ?? 0
        
        print("🎯 Trick evaluation complete - Winner: \(winner.name) with card at index \(winningCardIndex)")
        
        // Add brisques to winner's count
        for card in currentTrick {
            if card.isBrisque {
                brisques[winner.id, default: 0] += 1
            }
        }
        
        // Set the current player to the trick winner
        currentPlayerIndex = winnerIndex
        currentPlayer.isCurrentPlayer = true
        
        // Clear previous player's current status
        for (index, player) in players.enumerated() {
            if index != currentPlayerIndex {
                player.isCurrentPlayer = false
            }
        }
        
        // After first trick is complete, set flag to false
        isFirstTrick = false
        
        // Show trick winner message and animation
        lastTrickWinner = winner.name
        isShowingTrickResult = true
        isAnimatingWinningCard = true
        self.winningCardIndex = winningCardIndex
        
        // Complete the trick evaluation with minimal delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.finalizeTrickCompletion(winner: winner)
        }
    }
    
    // Finalize trick completion and set up for winner's next action
    private func finalizeTrickCompletion(winner: Player) {
        print("🏆 FINALIZING TRICK COMPLETION:")
        print("   Winner: \(winner.name)")
        print("   Winner type: \(winner.type)")
        print("   Current player before: \(currentPlayer.name)")
        print("   Current player index before: \(currentPlayerIndex)")
        print("   Current phase before: \(currentPhase)")
        print("   Is draw cycle before: \(isDrawCycle)")
        print("   Must draw card before: \(mustDrawCard)")
        print("   Current trick count before: \(currentTrick.count)")
        
        // Clear the trick area first
        clearTrickArea()
        
        // Set the winner as the current player
        if let winnerIndex = players.firstIndex(where: { $0.id == winner.id }) {
            currentPlayerIndex = winnerIndex
            print("   Set current player index to winner: \(currentPlayerIndex)")
        }
        
        // Clear all players' current status
        for (index, player) in players.enumerated() {
            player.isCurrentPlayer = (index == currentPlayerIndex)
        }
        
        // Set up for winner's next action
        currentPhase = .playing
        isDrawCycle = true
        mustDrawCard = true
        canPlayerMeld = true
        awaitingMeldChoice = true
        
        // Reset draw tracking for the new trick
        for player in players {
            hasDrawnForNextTrick[player.id] = false
        }
        
        // Set up draw cycle starting with the winner
        currentDrawIndex = currentPlayerIndex
        currentPlayIndex = currentPlayerIndex
        
        // Set the trick leader to the winner for the new trick
        currentTrickLeader = currentPlayerIndex
        
        print("   Current player after: \(currentPlayer.name)")
        print("   Current player index after: \(currentPlayerIndex)")
        print("   Current phase after: \(currentPhase)")
        print("   Is draw cycle after: \(isDrawCycle)")
        print("   Must draw card after: \(mustDrawCard)")
        print("   Can player meld after: \(canPlayerMeld)")
        print("   Current draw index: \(currentDrawIndex)")
        print("   Current play index: \(currentPlayIndex)")
        print("   Current trick leader: \(currentTrickLeader)")
        print("   Current trick count after: \(currentTrick.count)")
        print("   Has drawn for next trick (winner): \(hasDrawnForNextTrick[currentPlayer.id, default: false])")
        
        print("🏆 TRICK COMPLETION FINALIZED")
    }
    
    // Clear the trick area when winner takes action
    func clearTrickArea() {
        print("🧹 Clearing trick area")
        print("   Current trick count before clear: \(currentTrick.count)")
        currentTrick.removeAll()
        isShowingTrickResult = false
        lastTrickWinner = nil
        winningCardIndex = nil
        canPlayerMeld = false
        awaitingMeldChoice = false
        print("   Current trick count after clear: \(currentTrick.count)")
        print("   Is showing trick result: \(isShowingTrickResult)")
        print("   Can player meld: \(canPlayerMeld)")
        print("   Awaiting meld choice: \(awaitingMeldChoice)")
    }
    
    // Draw card for the current draw turn player
    func drawCardForCurrentDrawTurn() {
        let player = players[currentDrawIndex]
        print("🎴 DRAW ATTEMPT:")
        print("   Player: \(player.name)")
        print("   Has drawn: \(hasDrawnForNextTrick[player.id, default: false])")
        print("   Deck empty: \(deck.isEmpty)")
        print("   Must draw card: \(mustDrawCard)")
        
        guard hasDrawnForNextTrick[player.id] == false, !deck.isEmpty else { 
            print("❌ DRAW FAILED - Conditions not met")
            return 
        }
        
        if let card = deck.drawCard() {
            player.addCards([card])
            hasDrawnForNextTrick[player.id] = true
            print("✅ DRAW SUCCESS - \(player.name) drew \(card.displayName)")
        }
        
        // Advance to next draw turn
        currentDrawIndex = (currentDrawIndex + 1) % playerCount
        
        // Check if all players have drawn
        let allHaveDrawn = players.allSatisfy { hasDrawnForNextTrick[$0.id, default: false] }
        
        if allHaveDrawn {
            // All players have drawn, switch to play cycle
            print("🔄 All players have drawn - switching to play cycle")
            mustDrawCard = false
            currentPlayIndex = currentTrickLeader
            currentPlayerIndex = currentTrickLeader
            currentPlayer.isCurrentPlayer = true
            
            // Clear previous player's current status
            for (index, player) in players.enumerated() {
                if index != currentPlayerIndex {
                    player.isCurrentPlayer = false
                }
            }
        } else {
            // Set current player to the next player who needs to draw
            currentPlayerIndex = currentDrawIndex
            currentPlayer.isCurrentPlayer = true
            
            // Clear previous player's current status
            for (index, player) in players.enumerated() {
                if index != currentPlayerIndex {
                    player.isCurrentPlayer = false
                }
            }
        }
    }
    
    // Play card for the current play turn player
    func playCardForCurrentPlayTurn(_ card: PlayerCard) {
        let player = players[currentPlayIndex]
        print("🎯 PLAY ATTEMPT:")
        print("   Player: \(player.name)")
        print("   Has drawn: \(hasDrawnForNextTrick[player.id, default: false])")
        print("   Card: \(card.displayName)")
        print("   Current trick count: \(currentTrick.count)")
        print("   Player count: \(playerCount)")
        
        // Check for exceptions to the "must draw" rule
        let drawPileEmpty = deck.isEmpty
        
        print("   Is first trick: \(isFirstTrick)")
        print("   Draw pile empty: \(drawPileEmpty)")
        
        // Allow play if: has drawn OR it's the first trick OR draw pile is empty
        guard hasDrawnForNextTrick[player.id] == true || isFirstTrick || drawPileEmpty else { 
            print("❌ PLAY FAILED - Player hasn't drawn")
            return 
        }
        
        print("✅ PLAY SUCCESS - \(player.name) plays \(card.displayName)")
        
        // Add card to trick
        currentTrick.append(card)
        player.removeCard(card)
        
        // Advance to next play turn
        currentPlayIndex = (currentPlayIndex + 1) % playerCount
        
        // Check if all players have played
        if currentTrick.count == playerCount {
            print("🎯 All players have played - completing trick")
            completeTrick()
        } else {
            // Set current player to the next player
            currentPlayerIndex = currentPlayIndex
            currentPlayer.isCurrentPlayer = true
            
            // Clear previous player's current status
            for (index, p) in players.enumerated() {
                if index != currentPlayerIndex {
                    p.isCurrentPlayer = false
                }
            }
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
        awaitingMeldChoice = false
        mustDrawCard = false
        
        // Start new trick with the same player (trick winner)
        startNewTrick()
    }
    
    // Human player draws a card (called when they choose to draw)
    func drawCardForCurrentPlayer() {
        print("🎴 HUMAN DRAW ATTEMPT:")
        print("   Player: \(currentPlayer.name)")
        print("   Must draw card: \(mustDrawCard)")
        print("   Deck empty: \(deck.isEmpty)")
        print("   Can player meld: \(canPlayerMeld)")
        print("   Current phase: \(currentPhase)")
        print("   Is draw cycle: \(isDrawCycle)")
        print("   Current draw index: \(currentDrawIndex)")
        print("   Current play index: \(currentPlayIndex)")
        print("   Current player index: \(currentPlayerIndex)")
        print("   Has drawn for next trick: \(hasDrawnForNextTrick[currentPlayer.id, default: false])")
        print("   Current trick count: \(currentTrick.count)")
        print("   Is first trick: \(isFirstTrick)")
        print("   Is showing trick result: \(isShowingTrickResult)")
        print("   Last trick winner: \(lastTrickWinner ?? "none")")
        
        // Clear meld choice state when player draws
        awaitingMeldChoice = false
        
        // Clear the trick area when winner takes action
        clearTrickArea()
        
        if !deck.isEmpty {
            if let card = deck.drawCard() {
                currentPlayer.addCards([card])
                print("✅ DRAW SUCCESS - \(currentPlayer.name) drew \(card.displayName)")
                print("   Player hand count after draw: \(currentPlayer.hand.count)")
                
                // Mark that this player has drawn for the next trick
                hasDrawnForNextTrick[currentPlayer.id] = true
                print("   Updated has drawn for next trick: \(hasDrawnForNextTrick[currentPlayer.id, default: false])")
                
                // Check if we should start a new trick
                if currentTrick.isEmpty {
                    print("🔄 Starting new trick after draw")
                    startNewTrick()
                } else {
                    print("🔄 Continuing current trick after draw")
                    // Continue with current trick
                    currentPlayerIndex = currentPlayIndex
                    currentPlayer.isCurrentPlayer = true
                    
                    // Clear previous player's current status
                    for (index, player) in players.enumerated() {
                        if index != currentPlayerIndex {
                            player.isCurrentPlayer = false
                        }
                    }
                }
            }
        } else {
            print("⚠️ Deck is empty - no card to draw")
        }
        
        print("🎴 DRAW ATTEMPT COMPLETED")
        print("   Final current player: \(currentPlayer.name)")
        print("   Final current player index: \(currentPlayerIndex)")
        print("   Final has drawn for next trick: \(hasDrawnForNextTrick[currentPlayer.id, default: false])")
    }
    
    // MARK: - Trick Winner Determination
    
    func determineTrickWinner() -> Int {
        guard !currentTrick.isEmpty else {
            print("❌ No cards in current trick to determine winner")
            return currentTrickLeader
        }
        
        print("🎯 Determining trick winner...")
        print("   Current trick: \(currentTrick.map { "\(String(describing: $0.value)) of \(String(describing: $0.suit))" })")
        print("   Trump suit: \(trumpSuit?.rawValue ?? "None")")
        
        var winningCardIndex = 0
        var winningCard = currentTrick[0]
        
        for (index, card) in currentTrick.enumerated() {
            print("   Comparing card \(index): \(String(describing: card.value)) of \(String(describing: card.suit))")
            
            if card.canBeat(winningCard, trumpSuit: trumpSuit) {
                winningCardIndex = index
                winningCard = card
                print("   New winner: \(String(describing: card.value)) of \(String(describing: card.suit))")
            }
        }
        
        let winnerPlayerIndex = (currentTrickLeader + winningCardIndex) % players.count
        print("   Final winner: \(players[winnerPlayerIndex].name) with \(String(describing: winningCard.value)) of \(String(describing: winningCard.suit))")
        
        return winnerPlayerIndex
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
            // Clear meld choice state when player declares meld
            awaitingMeldChoice = false
            
            // Clear the trick area when winner takes action (declares meld)
            clearTrickArea()
            
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
        
        // Get all cards in player's hand (held + melded)
        let allCards = player.hand + player.meldsDeclared.flatMap { $0.cards }
        
        // Check for Bésigue (Queen of Spades + Jack of Diamonds)
        let queenOfSpades = allCards.first { $0.value == .queen && $0.suit == .spades }
        let jackOfDiamonds = allCards.first { $0.value == .jack && $0.suit == .diamonds }
        
        if queenOfSpades != nil && jackOfDiamonds != nil {
            possibleMelds.append(Meld(type: .besigue, cards: [queenOfSpades!, jackOfDiamonds!], points: 40))
        }
        
        // Check for marriages (King + Queen of same suit)
        for suit in Suit.allCases {
            let king = allCards.first { $0.value == .king && $0.suit == suit }
            let queen = allCards.first { $0.value == .queen && $0.suit == suit }
            
            if king != nil && queen != nil {
                let isTrump = suit == trumpSuit
                let meldType: MeldType = isTrump ? .royalMarriage : .commonMarriage
                let points = isTrump ? 40 : 20
                possibleMelds.append(Meld(type: meldType, cards: [king!, queen!], points: points))
            }
        }
        
        // Check for four of a kind
        for value in CardValue.allCases {
            let fourOfKind = allCards.filter { $0.value == value }
            if fourOfKind.count >= 4, let meldType = MeldType.forValue(value) {
                possibleMelds.append(Meld(type: meldType, cards: Array(fourOfKind.prefix(4)), points: 100))
            }
        }
        
        // Check for four jokers (four-of-a-kind)
        let jokers = allCards.filter { $0.isJoker }
        if jokers.count >= 4 {
            possibleMelds.append(Meld(type: .fourJokers, cards: Array(jokers.prefix(4)), points: 200))
        }
        
        return possibleMelds
    }
    
    var dealerDetermined: Bool {
        return currentPhase != .dealerDetermination
    }
    
    // Check if current player can draw a card
    func canCurrentPlayerDraw() -> Bool {
        let mustDraw = mustDrawCard
        let deckNotEmpty = !deck.isEmpty
        let hasNotDrawn = !hasDrawnForNextTrick[currentPlayer.id, default: false]
        let canDraw = mustDraw && deckNotEmpty && hasNotDrawn
        
        print("🔍 CAN DRAW CHECK:")
        print("   Player: \(currentPlayer.name)")
        print("   Must draw card: \(mustDraw)")
        print("   Deck empty: \(deck.isEmpty)")
        print("   Has drawn: \(hasDrawnForNextTrick[currentPlayer.id, default: false])")
        print("   Current phase: \(currentPhase)")
        print("   Is draw cycle: \(isDrawCycle)")
        print("   Is showing trick result: \(isShowingTrickResult)")
        print("   Last trick winner: \(lastTrickWinner ?? "none")")
        print("   Current trick count: \(currentTrick.count)")
        print("   Can player meld: \(canPlayerMeld)")
        print("   Result: \(canDraw)")
        
        return canDraw
    }
    
    // Check if current player can play a card (includes trick fullness check)
    func canPlayCard() -> Bool {
        // In unrestricted mode, only check if trick is not full
        if isUnrestrictedMode {
            let trickNotFull = currentTrick.count < playerCount
            print("🔍 CAN PLAY CARD (UNRESTRICTED):")
            print("   Player: \(currentPlayer.name)")
            print("   Trick count: \(currentTrick.count)")
            print("   Player count: \(playerCount)")
            print("   Trick not full: \(trickNotFull)")
            print("   Result: \(trickNotFull)")
            return trickNotFull
        }
        
        // Normal mode - check all restrictions
        let hasDrawn = hasDrawnForNextTrick[currentPlayer.id, default: false]
        let trickNotFull = currentTrick.count < playerCount
        let drawPileEmpty = deck.isEmpty
        
        print("🔍 CAN PLAY CARD CHECK:")
        print("   Player: \(currentPlayer.name)")
        print("   Has drawn: \(hasDrawn)")
        print("   Trick count: \(currentTrick.count)")
        print("   Player count: \(playerCount)")
        print("   Trick not full: \(trickNotFull)")
        print("   Is first trick: \(isFirstTrick)")
        print("   Draw pile empty: \(drawPileEmpty)")
        print("   Result: \((hasDrawn || isFirstTrick || drawPileEmpty) && trickNotFull)")
        
        // Can play if: (has drawn OR it's the first trick OR draw pile empty) AND trick is not full
        return (hasDrawn || isFirstTrick || drawPileEmpty) && trickNotFull
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
        
        // Enable drawing for the trick winner
        mustDrawCard = true
        
        print("🔄 Draw cycle started - \(players[trickWinnerIndex].name) can draw a card")
    }
    
    // MARK: - Tiebreaker Logic
    
    /// Resolve ties in final scoring by drawing cards for Jacks
    func resolveTies() {
        let sortedPlayers = players.sorted { $0.score > $1.score }
        var tiedGroups: [[Player]] = []
        var currentGroup: [Player] = []
        var currentScore = sortedPlayers.first?.score ?? 0
        
        // Group players by score
        for player in sortedPlayers {
            if player.score == currentScore {
                currentGroup.append(player)
            } else {
                if currentGroup.count > 1 {
                    tiedGroups.append(currentGroup)
                }
                currentGroup = [player]
                currentScore = player.score
            }
        }
        
        // Handle last group
        if currentGroup.count > 1 {
            tiedGroups.append(currentGroup)
        }
        
        // Resolve each tie group
        for tiedGroup in tiedGroups {
            resolveTieGroup(tiedGroup)
        }
    }
    
    /// Resolve a specific group of tied players
    private func resolveTieGroup(_ tiedPlayers: [Player]) {
        guard tiedPlayers.count > 1 else { return }
        
        isInTiebreaker = true
        tiebreakerPlayers = tiedPlayers
        tiebreakerCards.removeAll()
        
        // Create a temporary deck for tiebreaker
        let tiebreakerDeck = Deck()
        tiebreakerDeck.shuffle()
        
        print("🎯 Resolving tie between: \(tiedPlayers.map { $0.name }.joined(separator: ", "))")
        
        // Each tied player draws one card at a time
        for (index, player) in tiedPlayers.enumerated() {
            if let card = tiebreakerDeck.drawCard() {
                tiebreakerCards.append(card)
                print("🎴 \(player.name) draws \(card.imageName)")
                
                // If Jack is drawn, this player loses the tie
                if !card.isJoker && card.value == .jack {
                    tiebreakerMessage = "\(player.name) draws a Jack and drops in ranking!"
                    print("🎯 \(player.name) draws Jack - loses tie")
                    
                    // Move this player to the end of the tied group
                    if let playerIndex = players.firstIndex(where: { $0.id == player.id }) {
                        let playerToMove = players.remove(at: playerIndex)
                        players.append(playerToMove)
                    }
                    
                    // Continue with remaining players
                    let remainingPlayers = Array(tiedPlayers.dropFirst(index + 1))
                    if remainingPlayers.count > 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.resolveTieGroup(remainingPlayers)
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.completeTiebreaker()
                        }
                    }
                    return
                }
            }
        }
        
        // If no Jack was drawn, all players keep their current ranking
        tiebreakerMessage = "No Jack drawn - all players keep current ranking"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.completeTiebreaker()
        }
    }
    
    /// Complete the tiebreaker process
    private func completeTiebreaker() {
        isInTiebreaker = false
        tiebreakerPlayers.removeAll()
        tiebreakerCards.removeAll()
        tiebreakerMessage = ""
        
        print("✅ Tiebreaker completed")
        
        // Check if game is over
        if hasWinner() {
            currentPhase = .gameOver
        }
    }
    
    // MARK: - Endgame Detection
    /// Check if we're in endgame (no more cards to draw)
    func checkEndgame() {
        let shouldBeEndgame = deck.isEmpty
        if shouldBeEndgame && !isEndgame {
            isEndgame = true
            print("🏁 ENDGAME: No more cards to draw - stricter rules apply")
        }
    }
}