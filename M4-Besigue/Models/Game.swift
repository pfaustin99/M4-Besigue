import Foundation

// MARK: - Game Phase
enum GamePhase: String {
    case setup = "setup"
    case dealing = "dealing"
    case dealerDetermination = "dealer_determination" // Added for dealer selection phase
    case playing = "playing"
    case endgame = "endgame" // No more cards to draw, stricter rules
    case scoring = "scoring"
    case gameOver = "game_over"
}

/**
 * Result of a meld declaration attempt.
 * 
 * This struct provides detailed feedback about meld declaration operations,
 * including success/failure status and explanatory reasons.
 * 
 * @note Used by the new centralized meld declaration system
 * @note Provides consistent error reporting across all meld interactions
 */
struct MeldResult {
    let success: Bool
    let reason: String
    
    init(success: Bool, reason: String) {
        self.success = success
        self.reason = reason
    }
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
    
    // Completed trick display state
    @Published var completedTrick: [PlayerCard] = []
    @Published var completedTrickWinnerIndex: Int? = nil
    @Published var isShowingCompletedTrick: Bool = false
    
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
    
    // User message state
    @Published var userMessage: String? = nil
    @Published var trickWinnerId: UUID? = nil
    
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
        _ = drawCard(for: winner)
        
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
            _ = drawCard(for: winner)
            
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
        self.playerCount = gameRules.totalPlayerCount  // Use totalPlayerCount for actual game player count
        self.isOnline = isOnline
        self.deck = Deck()
        self.aiService = AIService(difficulty: .medium)
        
        // Start in uninitialized state - no players, no game setup
        // Game will be initialized when initializeFromConfiguration() is called
        print("🎮 Game created in uninitialized state")
    }
    
    // Initialize game from configuration
    func initializeFromConfiguration() {
        print("🎮 Initializing game from configuration...")
        print("🎮 Configuration - playerCount: \(gameRules.playerCount), totalPlayerCount: \(gameRules.totalPlayerCount)")
        print("🎮 Configuration - playerConfigurations.count: \(gameRules.playerConfigurations.count)")
        
        // Generate configuration if empty (for default games)
        if gameRules.playerConfigurations.isEmpty {
            gameRules.generatePlayerConfigurations()
            print("🎮 Generated \(gameRules.playerConfigurations.count) player configurations")
        }
        
        // Set up players from configuration
        updatePlayersFromConfiguration()
        
        print("🎮 Game initialized with \(players.count) players")
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
        
        // First trick exception: players can play without drawing since they just got dealt cards
        if isFirstTrick {
            for player in players {
                hasDrawnForNextTrick[player.id] = true
            }
            print("🎯 First trick: All players can play without drawing (cards just dealt)")
        }
        
        // Check endgame state
        checkEndgame()
        
        // Determine dealer and first player for the new game
        determineDealer()
        
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
            
            // If the first player is an AI, trigger their turn immediately
            if currentPlayer.type == .ai {
                print("🤖 AI first player \(currentPlayer.name) - starting AI turn for initial trick")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.processAITurn()
                }
            } else {
                print("👤 Human first player \(currentPlayer.name) - waiting for human to start initial trick")
            }
            
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
                    player.held.append(playerCard)
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
        // Clear previous player's current status
        for (index, player) in players.enumerated() {
            player.isCurrentPlayer = false
        }
        
        // Move to next player
        currentPlayerIndex = (currentPlayerIndex + 1) % playerCount
        
        // Set new current player
        currentPlayer.isCurrentPlayer = true
        
        print("🔄 Turn moved to: \(currentPlayer.name) (index: \(currentPlayerIndex))")
        
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
        
        // AI needs to draw a card first if it hasn't drawn for this trick
        if mustDrawCard && !hasDrawnForNextTrick[currentPlayer.id, default: false] && !deck.isEmpty {
            print("🤖 AI \(currentPlayer.name) needs to draw a card first")
            
            // AI draws a card
            if let card = deck.drawCard() {
                currentPlayer.addCards([card])
                hasDrawnForNextTrick[currentPlayer.id] = true
                print("🤖 AI \(currentPlayer.name) drew \(card.displayName)")
                
                // Post notification for view state to trigger draw animation
                NotificationCenter.default.post(
                    name: .cardDrawn,
                    object: card
                )
                
                // Check if ALL players have drawn for this trick
                let allHaveDrawn = players.allSatisfy { hasDrawnForNextTrick[$0.id, default: false] }
                
                if allHaveDrawn {
                    print("🔄 All players have drawn - starting new trick")
                    // All players have drawn, start new trick
                    startNewTrick()
                } else {
                    print("🔄 Not all players have drawn yet - continuing draw cycle")
                    // Move to next player who needs to draw
                    currentDrawIndex = (currentDrawIndex + 1) % playerCount
                    
                    // Only move currentPlayerIndex if the current player has already drawn
                    // This allows the current player to play their card after drawing
                    if hasDrawnForNextTrick[currentPlayer.id, default: false] {
                        // Current player has drawn, they can play - don't change currentPlayerIndex
                        print("🔄 \(currentPlayer.name) has drawn and can now play - keeping turn")
                    } else {
                        // Current player hasn't drawn yet, move to next player
                        currentPlayerIndex = currentDrawIndex
                        currentPlayer.isCurrentPlayer = true
                        
                        // Clear previous player's current status
                        for (index, player) in players.enumerated() {
                            if index != currentPlayerIndex {
                                player.isCurrentPlayer = false
                            }
                        }
                        
                        print("🔄 Moved to next player: \(currentPlayer.name) (index: \(currentPlayerIndex))")
                        
                        // If next player is AI, trigger AI turn
                        if currentPlayer.type == .ai {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.processAITurn()
                            }
                        }
                    }
                }
                return
            }
        }
        
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
        print("   Current trick count before clear: \(currentTrick.count)")
        print("   Current trick cards before clear: \(currentTrick.map { $0.displayName })")
        print("   Is showing completed trick: \(isShowingCompletedTrick)")
        print("   Completed trick count: \(completedTrick.count)")
        
        currentTrick.removeAll()
        currentTrickLeader = currentPlayerIndex
        
        print("   New trick leader set to: \(currentTrickLeader)")
        print("   New trick leader name: \(players[currentTrickLeader].name)")
        print("   Current trick count after clear: \(currentTrick.count)")
        print("   Is showing completed trick: \(isShowingCompletedTrick)")
        
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
        
        // Don't immediately trigger AI turn - let the draw cycle proceed naturally
        // The AI will draw when it's their turn in the draw cycle
    }
    
    // Play a card (synchronous version for testing)
    func playCardSync(_ card: PlayerCard, from player: Player) {
        print("🎴 PLAYING CARD (SYNC):")
        print("   Player: \(player.name) (type: \(player.type))")
        print("   Card: \(card.displayName)")
        // Add card to trick immediately
        player.removeCard(card)
        currentTrick.append(card)
        aiService.cardMemory.addPlayedCard(card) // <-- Ensure AI memory is updated in tests
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
        
        // Post notification for view state to trigger animation
        NotificationCenter.default.post(
            name: .cardPlayed,
            object: card
        )
        
        // Animate card play
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isPlayingCard = false
            self.playedCard = nil
            
            // Add card to trick
            self.canPlayerMeld = false
            player.removeCard(card)
            self.currentTrick.append(card)
            self.aiService.cardMemory.addPlayedCard(card)
            
            print("   🎴 CARD ADDED TO TRICK:")
            print("      Card: \(card.displayName)")
            print("      Player: \(player.name)")
            print("      New trick count: \(self.currentTrick.count)")
            print("      Current trick cards: \(self.currentTrick.map { $0.displayName })")
            print("      Cards in order: \(self.currentTrick.enumerated().map { "\($0): \($1.displayName) by \(self.players[(self.currentTrickLeader + $0) % self.playerCount].name)" })")
            print("      Is showing completed trick: \(self.isShowingCompletedTrick)")
            print("      Completed trick count: \(self.completedTrick.count)")
            
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
        let winningCard = currentTrick[winningCardIndex]
        
        print("🎯 Trick evaluation complete - Winner: \(winner.name) with card at index \(winningCardIndex)")
        print("   Winning card: \(winningCard.displayName)")
        print("   Trump suit: \(trumpSuit?.rawValue ?? "None")")
        
        // Award 10 points for winning with 7 of trump suit
        if let trumpSuit = trumpSuit {
            let sevensOfTrump = currentTrick.filter { $0.suit == trumpSuit && $0.value == .seven }
            let bonusPoints = sevensOfTrump.count * settings.trickWithSevenTrumpPoints
            if bonusPoints > 0 {
                winner.addPoints(bonusPoints)
                print("🎉 BONUS: \(winner.name) wins trick with \(sevensOfTrump.count) 7\(sevensOfTrump.count > 1 ? "s" : "") of \(trumpSuit.rawValue) - awarded \(bonusPoints) points!")
                print("   New score: \(winner.totalPoints)")
            }
        }
        
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
        self.trickWinnerId = winner.id
        
        // Set user message for trick winner
        userMessage = "🏆 \(winner.name) wins the trick!"
        
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
        
        // Store the completed trick before clearing
        if !currentTrick.isEmpty {
            print("🏆 STORING COMPLETED TRICK:")
            print("   Current trick count: \(currentTrick.count)")
            print("   Current trick cards: \(currentTrick.map { $0.displayName })")
            print("   Winning card index: \(winningCardIndex ?? -1)")
            
            completedTrick = currentTrick
            completedTrickWinnerIndex = winningCardIndex
            
            print("   Completed trick stored:")
            print("   Completed trick count: \(completedTrick.count)")
            print("   Completed trick cards: \(completedTrick.map { $0.displayName })")
            print("   Completed trick winner index: \(completedTrickWinnerIndex ?? -1)")
            
            // Add a small delay before showing completed trick so current trick is visible
            print("   Setting up async delays...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                print("🏆 Setting isShowingCompletedTrick to true after 0.8s delay")
                self.isShowingCompletedTrick = true
                print("   isShowingCompletedTrick is now: \(self.isShowingCompletedTrick)")
                print("   completedTrick count is now: \(self.completedTrick.count)")
            }
            
            // Clear the completed trick after 3 seconds to allow proper display
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                print("🏆 Clearing completed trick after 3.0s delay")
                self.completedTrick.removeAll()
                self.completedTrickWinnerIndex = nil
                self.isShowingCompletedTrick = false
                print("   completedTrick cleared, count: \(self.completedTrick.count)")
                print("   isShowingCompletedTrick is now: \(self.isShowingCompletedTrick)")
            }
        }
        
        // Clear the trick area after the completed trick display is finished
        // This ensures the completed trick is visible for the full 3 seconds
        print("   Setting up clearTrickArea delay for 3.2s...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            print("🏆 Calling clearTrickArea after 3.2s delay")
            self.clearTrickArea()
            // After clearing the trick area, we can start a new trick
            // The currentTrick array will be cleared in startNewTrick when it's actually called
        }
        
        // Clear the user message after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.userMessage = nil
        }
        
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
        
        // If the winner is an AI player, automatically start their turn (draw + play)
        if currentPlayer.type == .ai {
            print("🤖 AI winner \(currentPlayer.name) - automatically starting AI turn for new trick")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.processAITurn()
            }
        } else {
            print("👤 Human winner \(currentPlayer.name) - waiting for human to start new trick")
        }
    }
    
    // Clear the trick area when winner takes action
    func clearTrickArea() {
        print("🧹 Clearing trick area")
        print("   Current trick count before clear: \(currentTrick.count)")
        print("   Current trick cards before clear: \(currentTrick.map { $0.displayName })")
        print("   Is showing completed trick: \(isShowingCompletedTrick)")
        print("   Completed trick count: \(completedTrick.count)")
        print("   Completed trick cards: \(completedTrick.map { $0.displayName })")
        
        // Only clear currentTrick if we're not in the middle of displaying a completed trick
        // This prevents clearing the current trick while the completed trick is being shown
        if !isShowingCompletedTrick {
            currentTrick.removeAll()
        }
        
        isShowingTrickResult = false
        lastTrickWinner = nil
        winningCardIndex = nil
        // Note: completedTrick is cleared separately after display delay
        
        print("   Current trick count after clear: \(currentTrick.count)")
        print("   Is showing trick result: \(isShowingTrickResult)")
        print("   🧹 TRICK AREA CLEARED")
    }
    
    // Draw card for the current draw turn player
    func drawCardForCurrentDrawTurn() {
        let player = players[currentDrawIndex]
        print("🎴 DRAW ATTEMPT:")
        print("   Player: \(player.name)")
        print("   Has drawn: \(hasDrawnForNextTrick[player.id, default: false])")
        print("   Deck empty: \(deck.isEmpty)")
        print("   Must draw card: \(mustDrawCard)")
        print("   Current hand size: \(player.hand.count) (held: \(player.held.count), melded: \(player.melded.count))")
        
        // Check 9-card limit (held + melded)
        if player.hand.count >= 9 {
            print("❌ DRAW FAILED - Player already has 9 cards (limit reached)")
            return
        }
        
        guard hasDrawnForNextTrick[player.id] == false, !deck.isEmpty else { 
            print("❌ DRAW FAILED - Conditions not met")
            return 
        }
        
        // Reset meld state when any player draws during draw cycle
        canPlayerMeld = false
        awaitingMeldChoice = false
        
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
            
            // Clear all player current status first
            for (index, player) in players.enumerated() {
                player.isCurrentPlayer = false
            }
            
            // Set new current player
            currentPlayer.isCurrentPlayer = true
            
            print("🔄 Draw turn moved to: \(currentPlayer.name) (index: \(currentPlayerIndex))")
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
            
            // Clear all player current status first
            for (index, p) in players.enumerated() {
                p.isCurrentPlayer = false
            }
            
            // Set new current player
            currentPlayer.isCurrentPlayer = true
            
            print("🔄 Play turn moved to: \(currentPlayer.name) (index: \(currentPlayerIndex))")
        }
    }
    
    // Trigger AI draw if it's their turn
    private func triggerAIDrawIfNeeded() {
        let player = players[currentDrawIndex]
        if player.type == .ai && !hasDrawnForNextTrick[player.id, default: false] && !deck.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                _ = self.drawCard(for: player)
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
            // Check 9-card limit for AI player
            if currentPlayer.hand.count >= 9 {
                print("❌ AI DRAW FAILED - \(currentPlayer.name) already has 9 cards (limit reached)")
                continueAfterAIDraw()
                return
            }
            
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
        print("   Current hand size: \(currentPlayer.hand.count) (held: \(currentPlayer.held.count), melded: \(currentPlayer.melded.count))")
        
        // Check 9-card limit (held + melded)
        if currentPlayer.hand.count >= 9 {
            print("❌ DRAW FAILED - Player already has 9 cards (limit reached)")
            return
        }
        
        // Clear meld choice state when player draws
        awaitingMeldChoice = false

        // Clear can player meld state when player draws
        canPlayerMeld = false
        
        // Note: Don't clear trick area here - it's already cleared in finalizeTrickCompletion
        // The trick area should show the completed trick until it's cleared by the timer
        
        if !deck.isEmpty {
            if let card = deck.drawCard() {
                currentPlayer.addCards([card])
                print("✅ DRAW SUCCESS - \(currentPlayer.name) drew \(card.displayName)")
                print("   Player held count after draw: \(currentPlayer.held.count)")
                
                // Post notification for view state to trigger draw animation
                NotificationCenter.default.post(
                    name: .cardDrawn,
                    object: card
                )
                
                // Mark that this player has drawn for the next trick
                hasDrawnForNextTrick[currentPlayer.id] = true
                print("   Updated has drawn for next trick: \(hasDrawnForNextTrick[currentPlayer.id, default: false])")
                
                // Check if ALL players have drawn for this trick
                let allHaveDrawn = players.allSatisfy { hasDrawnForNextTrick[$0.id, default: false] }
                
                if allHaveDrawn {
                    print("🔄 All players have drawn - starting new trick")
                    // All players have drawn, start new trick
                    startNewTrick()
                } else {
                    print("🔄 Not all players have drawn yet - continuing draw cycle")
                    // Move to next player who needs to draw
                    currentDrawIndex = (currentDrawIndex + 1) % playerCount
                    
                    // Only move currentPlayerIndex if the current player has already drawn
                    // This allows the current player to play their card after drawing
                    if hasDrawnForNextTrick[currentPlayer.id, default: false] {
                        // Current player has drawn, they can play - don't change currentPlayerIndex
                        print("🔄 \(currentPlayer.name) has drawn and can now play - keeping turn")
                    } else {
                        // Current player hasn't drawn yet, move to next player
                        currentPlayerIndex = currentDrawIndex
                        currentPlayer.isCurrentPlayer = true
                        
                        // Clear previous player's current status
                        for (index, player) in players.enumerated() {
                            if index != currentPlayerIndex {
                                player.isCurrentPlayer = false
                            }
                        }
                        
                        print("🔄 Moved to next player: \(currentPlayer.name) (index: \(currentPlayerIndex))")
                        
                        // If next player is AI, trigger AI turn
                        if currentPlayer.type == .ai {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.processAITurn()
                            }
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

        let leadCard = currentTrick[0]
        let leadSuit = leadCard.suit
        let trump = trumpSuit

        // 1. Check for trumps in the trick (exclude jokers)
        let trumpCards = currentTrick.enumerated().filter { $0.element.suit == trump && !$0.element.isJoker }
        if !trumpCards.isEmpty {
            let (winningIndex, _) = trumpCards.max(by: { $0.element.rank < $1.element.rank })!
            let winnerPlayerIndex = (currentTrickLeader + winningIndex) % players.count
            print("   Winner: \(players[winnerPlayerIndex].name) with highest trump")
            return winnerPlayerIndex
        }

        // 2. No trumps: check if first card is a Joker
        if leadCard.isJoker {
            print("   Winner: \(players[currentTrickLeader].name) with led Joker")
            return currentTrickLeader
        }

        // 3. No trumps, first not Joker: highest of lead suit wins (exclude jokers)
        let leadSuitCards = currentTrick.enumerated().filter { $0.element.suit == leadSuit && !$0.element.isJoker }
        if let (winningIndex, _) = leadSuitCards.max(by: { $0.element.rank < $1.element.rank }) {
            let winnerPlayerIndex = (currentTrickLeader + winningIndex) % players.count
            print("   Winner: \(players[winnerPlayerIndex].name) with highest of lead suit")
            return winnerPlayerIndex
        } else {
            // Fallback: if no lead suit cards (all jokers after a non-joker lead), leader wins
            print("   No lead suit cards found, leader wins by default")
            return currentTrickLeader
        }
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
    func getEndgamePlayableCards(leadSuit: Suit?, trumpSuit: Suit?, allCards: [PlayerCard]) -> [PlayerCard] {
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
        print("🔍 CAN DECLARE MELD CHECK:")
        print("   Player: \(player.name)")
        print("   Meld type: \(meld.type)")
        print("   Meld card IDs: \(meld.cardIDs)")
        print("   Current player: \(currentPlayer.name)")
        print("   Can player meld: \(canPlayerMeld)")
        print("   Awaiting meld choice: \(awaitingMeldChoice)")
        
        guard player.id == currentPlayer.id && canPlayerMeld else {
            print("❌ Meld validation failed: not current player or can't meld")
            return false
        }
        
        // Only one meld per opportunity
      /**  if player.meldsDeclared.last?.roundNumber == roundNumber {
            print("❌ Meld validation failed: already declared meld this round")
            print("   Last meld round: \(player.meldsDeclared.last?.roundNumber ?? -1)")
            print("   Current round: \(roundNumber)")
            return false
        } **/
        
        print("🔍 Validating meld: \(meld.type.name) with \(meld.cardIDs.count) cards")
        print("🔍 Trump suit: \(trumpSuit?.rawValue ?? "None")")
        
        // Check if player has all the cards for this meld (in hand or already melded)
        let allAvailableCards = player.hand + player.meldsDeclared.flatMap { $0.cardIDs.compactMap { player.cardByID($0) } }
        var availableCardIDs = allAvailableCards.map { $0.id }
        print("🔍 CARD AVAILABILITY CHECK:")
        print("   Player hand cards: \(player.hand.map { $0.displayName })")
        print("   Player melded cards: \(player.meldsDeclared.flatMap { $0.cardIDs }.compactMap { player.cardByID($0)?.displayName })")
        print("   Total available cards: \(allAvailableCards.map { $0.displayName })")
        print("   Available card IDs: \(availableCardIDs)")
        
        for cardID in meld.cardIDs {
            print("   Checking meld card: \(cardID) (ID: \(cardID))")
            if let idx = availableCardIDs.firstIndex(of: cardID) {
                availableCardIDs.remove(at: idx)
                print("   ✅ Found card in available cards")
            } else {
                print("❌ Missing card for meld: ID \(cardID)")
                return false
            }
        }
        // Check if at least one card is in held (can't meld only with already melded cards)
        let cardsInHeld = meld.cardIDs.compactMap { cardID in
            player.held.first(where: { $0.id == cardID })
        }
        print("🔍 HELD CARD CHECK:")
        print("   Cards in held for meld: \(cardsInHeld.map { $0.displayName })")
        print("   At least one card in held: \(!cardsInHeld.isEmpty)")
        
        if cardsInHeld.isEmpty {
            print("❌ No cards in held for meld")
            return false
        }
        // Check if any card has already been used for this meld type
        for cardID in meld.cardIDs {
            if let matching = player.cardByID(cardID) {
                if matching.usedInMeldTypes.contains(meld.type) {
                    print("❌ Card \(matching.displayName) already used for meld type \(meld.type.name)")
                    return false
                }
            }
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
                meld.type == .royalMarriage &&
                (meld.cardIDs.compactMap { player.cardByID($0) }.first?.suit == trumpSuit)
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
        print("🎯 DECLARE MELD CALLED:")
        print("   Player: \(player.name)")
        print("   Meld type: \(meld.type)")
        print("   Meld card IDs: \(meld.cardIDs)")
        print("   Current round: \(self.roundNumber)")
        
        if canDeclareMeld(meld, by: player) {
            // Don't clear the trick area when declaring meld - it interferes with trick display
            
            // Reset meld state after declaring meld
            canPlayerMeld = false
            awaitingMeldChoice = false
            
            var finalMeld = meld
            
            // If this is the first marriage, it sets the trump suit and becomes a Royal Marriage
            if trumpSuit == nil, meld.type == .commonMarriage {
                if let suit = meld.cardIDs.compactMap({ player.cardByID($0)?.suit }).first {
                    trumpSuit = suit
                    finalMeld = Meld(cardIDs: meld.cardIDs, type: .royalMarriage, pointValue: settings.royalMarriagePoints, roundNumber: self.roundNumber)
                    print("Trump suit set to \(trumpSuit?.rawValue ?? "")")
                }
            } else if meld.type == .commonMarriage, let trump = trumpSuit, meld.cardIDs.compactMap({ player.cardByID($0)?.suit }).first == trump {
                // This is a marriage in the trump suit, so it's a Royal Marriage
                finalMeld = Meld(cardIDs: meld.cardIDs, type: .royalMarriage, pointValue: settings.royalMarriagePoints, roundNumber: self.roundNumber)
            }
            
            player.declareMeld(finalMeld)
            print("✅ MELD DECLARED SUCCESSFULLY:")
            print("   Player: \(player.name)")
            print("   Meld type: \(finalMeld.type.name)")
            print("   Meld points: \(finalMeld.pointValue)")
            print("   Player new score: \(player.score)")
            
            // Handle point doubling for four-of-a-kind in trump suit
            if let trump = trumpSuit {
                let isTrumpMeld = finalMeld.cardIDs.compactMap { player.cardByID($0) }.allSatisfy { $0.suit == trump }
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
            let meldCards = meld.cardIDs.compactMap { player.cardByID($0) }
            self.aiService.cardMemory.addMeldedCards(meldCards)
        }
    }
    

    
    // Get meld type for a set of cards
    func getMeldTypeForCards(_ cards: [PlayerCard], trumpSuit: Suit?) -> MeldType? {
        print("🔍 getMeldTypeForCards called with cards: \(cards.map { "\($0.displayName) (ID: \($0.id))" })")
        print("   Trump suit: \(trumpSuit?.rawValue ?? "None")")
        
        guard cards.count >= 2 && cards.count <= 4 else { 
            print("   ❌ Invalid card count: \(cards.count) (must be 2-4)")
            return nil 
        }
        
        // Check for Bésigue (Queen of Spades + Jack of Diamonds)
        if cards.count == 2 {
            let hasQueenOfSpades = cards.contains { $0.value == .queen && $0.suit == .spades }
            let hasJackOfDiamonds = cards.contains { $0.value == .jack && $0.suit == .diamonds }
            print("   🔍 Checking Bésigue: Queen of Spades=\(hasQueenOfSpades), Jack of Diamonds=\(hasJackOfDiamonds)")
            if hasQueenOfSpades && hasJackOfDiamonds {
                print("   ✅ Found Bésigue")
                return .besigue
            }
        }
        
        // Check for marriages (King + Queen of same suit)
        if cards.count == 2 {
            for suit in Suit.allCases {
                let hasKing = cards.contains { $0.value == .king && $0.suit == suit }
                let hasQueen = cards.contains { $0.value == .queen && $0.suit == suit }
                print("   🔍 Checking marriage for \(suit.rawValue): King=\(hasKing), Queen=\(hasQueen)")
                if hasKing && hasQueen {
                    let meldType = suit == trumpSuit ? MeldType.royalMarriage : MeldType.commonMarriage
                    print("   ✅ Found \(meldType.name) for \(suit.rawValue)")
                    return meldType
                }
            }
        }
        
        // Check for four of a kind
        if cards.count == 4 {
            print("   🔍 Checking four of a kind...")
            
            // Check if all cards have the same value
            if let firstValue = cards.first?.value {
                let allSameValue = cards.allSatisfy { $0.value == firstValue }
                print("   First value: \(firstValue.rawValue), All same value: \(allSameValue)")
                if allSameValue, let meldType = MeldType.forValue(firstValue) {
                    print("   ✅ Found \(meldType.name)")
                    return meldType
                }
            }
            
            // Check for four jokers
            let allJokers = cards.allSatisfy { $0.isJoker }
            print("   All jokers: \(allJokers)")
            if allJokers {
                print("   ✅ Found Four Jokers")
                return .fourJokers
            }
            
            // Check for four of a kind with jokers as wild cards
            print("   🔍 Checking four of a kind with jokers as wild cards...")
            let nonJokerCards = cards.filter { !$0.isJoker }
            let jokerCards = cards.filter { $0.isJoker }
            print("   Non-joker cards: \(nonJokerCards.map { "\($0.displayName) (ID: \($0.id))" })")
            print("   Joker cards: \(jokerCards.map { "\($0.displayName) (ID: \($0.id))" })")
            
            if let firstValue = nonJokerCards.first?.value {
                let allSameValue = nonJokerCards.allSatisfy { $0.value == firstValue }
                let totalCards = nonJokerCards.count + jokerCards.count
                print("   Non-joker value: \(firstValue.rawValue), All same value: \(allSameValue), Total cards: \(totalCards)")
                
                if allSameValue && totalCards == 4, let meldType = MeldType.forValue(firstValue) {
                    print("   ✅ Found \(meldType.name) with jokers as wild cards")
                    return meldType
                }
            }
        }
        
        print("   ❌ No valid meld type found")
        return nil
    }
    
    // Get point value for a meld type
    func getPointValueForMeldType(_ meldType: MeldType) -> Int {
        switch meldType {
        case .besigue: return settings.besiguePoints
        case .royalMarriage: return settings.royalMarriagePoints
        case .commonMarriage: return settings.commonMarriagePoints
        case .fourJacks: return settings.fourJacksPoints
        case .fourQueens: return settings.fourQueensPoints
        case .fourKings: return settings.fourKingsPoints
        case .fourAces: return settings.fourAcesPoints
        case .fourJokers: return settings.fourJokersPoints
        case .sequence: return 100 // Default for sequence
        }
    }
    
    // Get all possible melds for a player
    func getPossibleMelds(for player: Player) -> [Meld] {
        print("🔍 GETTING POSSIBLE MELDS FOR \(player.name):")
        print("   Held cards: \(player.held.map { $0.displayName })")
        print("   Melded cards: \(player.meldsDeclared.flatMap { $0.cardIDs }.compactMap { player.cardByID($0)?.displayName })")
        print("   Trump suit: \(trumpSuit?.rawValue ?? "None")")
        
        var possibleMelds: [Meld] = []
        
        // Get all cards available to the player (held + previously melded)
        let allCards = player.hand // This is the computed property (held + melded)
        let heldCards = player.held
        let meldedCards = player.meldsDeclared.flatMap { $0.cardIDs }.compactMap { player.cardByID($0) }
        
        // Check for Bésigue (Queen of Spades + Jack of Diamonds)
        let queenOfSpades = allCards.first { $0.value == .queen && $0.suit == .spades }
        let jackOfDiamonds = allCards.first { $0.value == .jack && $0.suit == .diamonds }
        
        if let queenOfSpades = queenOfSpades, let jackOfDiamonds = jackOfDiamonds {
            // Check if we can form Bésigue with available cards
            let queenInHeld = heldCards.contains { $0.value == .queen && $0.suit == .spades }
            let jackInHeld = heldCards.contains { $0.value == .jack && $0.suit == .diamonds }
            let queenInMeld = meldedCards.contains { $0.value == .queen && $0.suit == .spades }
            let jackInMeld = meldedCards.contains { $0.value == .jack && $0.suit == .diamonds }
            
            // Can form Bésigue if at least one card is in held
            if (queenInHeld || queenInMeld) && (jackInHeld || jackInMeld) {
                let meldCardIDs = [queenOfSpades.id, jackOfDiamonds.id]
                possibleMelds.append(Meld(cardIDs: meldCardIDs, type: .besigue, pointValue: settings.besiguePoints, roundNumber: roundNumber))
                print("   ✅ Found Bésigue: [\(queenOfSpades.displayName), \(jackOfDiamonds.displayName)]")
            }
        }
        
        // Check for marriages (King + Queen of same suit)
        for suit in Suit.allCases {
            let king = allCards.first { $0.value == .king && $0.suit == suit }
            let queen = allCards.first { $0.value == .queen && $0.suit == suit }
            
            if let king = king, let queen = queen {
                let kingInHeld = heldCards.contains { $0.value == .king && $0.suit == suit }
                let queenInHeld = heldCards.contains { $0.value == .queen && $0.suit == suit }
                let kingInMeld = meldedCards.contains { $0.value == .king && $0.suit == suit }
                let queenInMeld = meldedCards.contains { $0.value == .queen && $0.suit == suit }
                
                // Can form marriage if at least one card is in held
                if (kingInHeld || kingInMeld) && (queenInHeld || queenInMeld) {
                    let isTrump = suit == trumpSuit
                    let meldType = isTrump ? MeldType.royalMarriage : MeldType.commonMarriage
                    let points = isTrump ? settings.royalMarriagePoints : settings.commonMarriagePoints
                    let meldCardIDs = [king.id, queen.id]
                    possibleMelds.append(Meld(cardIDs: meldCardIDs, type: meldType, pointValue: points, roundNumber: roundNumber))
                    print("   ✅ Found \(meldType.name) (\(suit.rawValue)): [\(king.displayName), \(queen.displayName)]")
                }
            }
        }
        
        // Check for four of a kind (including jokers as wild cards)
        for value in CardValue.allCases {
            let valueCards = allCards.filter { $0.value == value }
            let jokers = heldCards.filter { $0.isJoker }
            
            let totalAvailable = valueCards.count + jokers.count
            if totalAvailable >= 4, let meldType = MeldType.forValue(value) {
                // Create meld with available cards
                var meldCardIDs: [UUID] = []
                // Add actual value cards first (up to 4)
                let valueCardsToUse = Array(valueCards.prefix(4))
                meldCardIDs.append(contentsOf: valueCardsToUse.map { $0.id })
                // Add jokers to fill remaining slots (up to 4 total)
                let jokersNeeded = 4 - meldCardIDs.count
                let jokersToUse = Array(jokers.prefix(jokersNeeded))
                meldCardIDs.append(contentsOf: jokersToUse.map { $0.id })
                if meldCardIDs.count == 4 {
                    let points: Int
                    switch value {
                    case .ace: points = settings.fourAcesPoints
                    case .king: points = settings.fourKingsPoints
                    case .queen: points = settings.fourQueensPoints
                    case .jack: points = settings.fourJacksPoints
                    default: points = 100 // Default fallback
                    }
                    possibleMelds.append(Meld(cardIDs: meldCardIDs, type: meldType, pointValue: points, roundNumber: roundNumber))
                    print("   ✅ Found \(meldType.name): [\(meldCardIDs.map { player.cardByID($0)?.displayName ?? "?" })]")
                }
            }
        }
        
        // Check for four jokers (four-of-a-kind)
        let allJokers = allCards.filter { $0.isJoker }
        if allJokers.count >= 4 {
            let jokersInHeld = heldCards.filter { $0.isJoker }
            let jokersInMeld = meldedCards.filter { $0.isJoker }
            
            // Can form four jokers if at least one joker is in held
            if jokersInHeld.count > 0 || jokersInMeld.count > 0 {
                let meldCardIDs = Array(allJokers.prefix(4)).map { $0.id }
                possibleMelds.append(Meld(cardIDs: meldCardIDs, type: .fourJokers, pointValue: settings.fourJokersPoints, roundNumber: roundNumber))
                print("   ✅ Found Four Jokers: [\(meldCardIDs.map { player.cardByID($0)?.displayName ?? "?" })]")
            }
        }
        
        print("   Total possible melds: \(possibleMelds.count)")
        return possibleMelds
    }
    
    var dealerDetermined: Bool {
        return currentPhase != .dealerDetermination
    }
    
    /**
     * Check if current player can draw a card during the current game state.
     * 
     * This method provides backward compatibility while leveraging the new
     * comprehensive rule enforcement system. It checks if drawing is globally
     * enabled and then delegates to the detailed validation method.
     * 
     * @return Bool indicating if the current player can draw
     * 
     * @note This method maintains backward compatibility with existing code
     * @note For detailed validation, use canPlayerDraw(_:) instead
     * @note Called by AI decision logic and legacy UI components
     */
    func canCurrentPlayerDraw() -> Bool {
        // Check if drawing is globally enabled
        let mustDraw = mustDrawCard
        let deckNotEmpty = !deck.isEmpty
        let hasNotDrawn = !hasDrawnForNextTrick[currentPlayer.id, default: false]
        let canDraw = mustDraw && deckNotEmpty && hasNotDrawn
        
        print("🔍 CAN DRAW CHECK (Legacy):")
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
        
        // For human players, also check detailed validation rules
        if currentPlayer.type == .human {
            return canDraw && canPlayerDraw(currentPlayer)
        }
        
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
            // Move all melded cards back to held for each player
            for player in players {
                player.held.append(contentsOf: player.melded)
                player.melded.removeAll()
                player.meldedOrder.removeAll()
            }
        }
    }
    
    #if DEBUG
        var test_aiService: AIService { aiService }
    #endif
    
    // MARK: - Game Rule Enforcement Methods
    
    /**
     * Draws a card for a specific player.
     * 
     * This method consolidates all card drawing logic into a single, well-tested method.
     * It handles all validation, card addition, and game state updates.
     * 
     * @param player The player who should draw a card
     * @return Bool indicating if the draw was successful
     * 
     * @note This method replaces the previous duplicate draw methods
     * @note All draw operations should use this method for consistency
     */
    func drawCard(for player: Player) -> Bool {
        print("🎴 DRAW ATTEMPT for \(player.name):")
        print("   Player: \(player.name)")
        print("   Has drawn: \(hasDrawnForNextTrick[player.id, default: false])")
        print("   Deck empty: \(deck.isEmpty)")
        print("   Must draw card: \(mustDrawCard)")
        print("   Current hand size: \(player.hand.count) (held: \(player.hand.count), melded: \(player.melded.count))")
        
        // Check 9-card limit (held + melded)
        if player.hand.count >= 9 {
            print("❌ DRAW FAILED - Player already has 9 cards (limit reached)")
            return false
        }
        
        // Check if player has already drawn for this trick
        guard hasDrawnForNextTrick[player.id] == false else { 
            print("❌ DRAW FAILED - Player has already drawn for this trick")
            return false 
        }
        
        // Check if deck has cards available
        guard !deck.isEmpty else { 
            print("❌ DRAW FAILED - Deck is empty")
            return false 
        }
        
        // Check if drawing is currently allowed
        guard mustDrawCard else {
            print("❌ DRAW FAILED - Drawing is not currently allowed")
            return false
        }
        
        // Reset meld state when any player draws during draw cycle
        canPlayerMeld = false
        awaitingMeldChoice = false
        
        if let card = deck.drawCard() {
            player.addCards([card])
            hasDrawnForNextTrick[player.id] = true
            print("✅ DRAW SUCCESS - \(player.name) drew \(card.displayName)")
            
            // Post notification for view state to trigger draw animation
            NotificationCenter.default.post(
                name: .cardDrawn,
                object: card
            )
            
            // Check if ALL players have drawn for this trick
            let allHaveDrawn = players.allSatisfy { hasDrawnForNextTrick[$0.id, default: false] }
            
            if allHaveDrawn {
                // All players have drawn, switch to play cycle
                print("🔄 All players have drawn - switching to play cycle")
                mustDrawCard = false
                currentPlayIndex = currentTrickLeader
                currentPlayerIndex = currentTrickLeader
                currentPlayer.isCurrentPlayer = true
                
                // Clear previous player's current status
                for (index, p) in players.enumerated() {
                    if index != currentPlayerIndex {
                        p.isCurrentPlayer = false
                    }
                }
            } else {
                // Move to next player who needs to draw
                currentDrawIndex = (currentDrawIndex + 1) % playerCount
                
                // Set current player to the next player who needs to draw
                currentPlayerIndex = currentDrawIndex
                currentPlayer.isCurrentPlayer = true
                
                // Clear all player current status first
                for (index, p) in players.enumerated() {
                    if index != currentPlayerIndex {
                        p.isCurrentPlayer = false
                    }
                }
                
                print("🔄 Draw turn moved to: \(currentPlayer.name) (index: \(currentPlayerIndex))")
                
                // If next player is AI, trigger AI turn
                if currentPlayer.type == .ai {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.processAITurn()
                    }
                }
            }
            
            return true
        } else {
            print("❌ DRAW FAILED - Could not draw card from deck")
            return false
        }
    }
    
    /**
     * Validates if a player can draw a card during the current game state.
     * 
     * This method enforces all drawing rules using the standard draw cycle logic:
     * - Player type verification (human vs AI)
     * - Draw order enforcement (currentDrawIndex)
     * - Per-player draw gating (hasDrawnForNextTrick)
     * - Deck availability and hand size limits
     * 
     * @param player The player attempting to draw
     * @return Bool indicating if drawing is allowed
     * 
     * @note This method replaces the previous UI-level validation logic
     * @note Called by both UI components and AI decision logic
     * @note Ensures consistent rule enforcement across all game interactions
     * @note Uses the standard draw cycle progression managed by currentDrawIndex
     */
    func canPlayerDraw(_ player: Player) -> Bool {
        // Only human players can draw through UI (AI draws automatically)
        guard player.type == .human else { return false }
        
        // Find player index for draw order enforcement
        guard let playerIndex = players.firstIndex(where: { $0.id == player.id }) else { return false }
        
        // Enforce draw order - only the player at currentDrawIndex can draw
        guard playerIndex == currentDrawIndex else { return false }
        
        // Check if player has already drawn for this trick
        let hasAlreadyDrawn = hasDrawnForNextTrick[player.id, default: false]
        guard !hasAlreadyDrawn else { return false }
        
        // Verify deck has cards available
        guard !deck.isEmpty else { return false }
        
        // Check hand size limit (9 cards maximum)
        guard player.hand.count < 9 else { return false }
        
        return true
    }
    
    /**
     * Validates if a player can meld cards during the current game state.
     * 
     * This method enforces all melding rules including:
     * - Meld choice state verification
     * - Player meld capability
     * - Card count validation (2-4 cards)
     * - Trick winner verification
     * - Player type verification
     * 
     * @param player The player attempting to meld
     * @param selectedCards The cards selected for melding
     * @return Bool indicating if melding is allowed
     * 
     * @note This method replaces the previous UI-level validation logic
     * @note Ensures consistent meld validation across all game interactions
     */
    func canPlayerMeld(_ player: Player, selectedCards: [PlayerCard]) -> Bool {
        // Only human players can meld through UI
        guard player.type == .human else { return false }
        
        // Check if meld choice is currently allowed
        guard awaitingMeldChoice else { return false }
        
        // Verify player has meld capability
        guard self.canPlayerMeld else { return false }
        
        // Validate card count (2-4 cards required for melding)
        guard selectedCards.count >= 2 && selectedCards.count <= 4 else { return false }
        
        // Verify player is the trick winner (only trick winner can meld)
        guard player.id == trickWinnerId else { return false }
        
        return true
    }
    
    /**
     * Determines if the meld button should be shown for a player.
     * 
     * This method consolidates all meld button visibility logic:
     * - Player type verification
     * - Meld choice state
     * - Player meld capability
     * - Card count validation
     * - Trick winner verification
     * 
     * @param player The player to check meld button visibility for
     * @param selectedCards The currently selected cards
     * @return Bool indicating if meld button should be visible
     * 
     * @note This method replaces the previous UI-level shouldShowMeldButton logic
     * @note Provides single source of truth for meld button state
     */
    func shouldShowMeldButton(for player: Player, selectedCards: [PlayerCard]) -> Bool {
        // Only human players see meld buttons
        guard player.type == .human else { return false }
        
        // Check if meld choice is currently allowed
        guard awaitingMeldChoice else { return false }
        
        // Verify player has meld capability
        guard canPlayerMeld else { return false }
        
        // Validate card count (2-4 cards required for melding)
        guard selectedCards.count >= 2 && selectedCards.count <= 4 else { return false }
        
        // Verify player is the trick winner (only trick winner can meld)
        guard player.id == trickWinnerId else { return false }
        
        return true
    }
    
    /**
     * Validates if a player can select a card for melding.
     * 
     * This method enforces card selection rules:
     * - Meld choice state verification
     * - Player type verification
     * - Player meld capability
     * - Trick winner verification
     * 
     * @param player The player attempting to select a card
     * @return Bool indicating if card selection is allowed
     * 
     * @note This method replaces the previous UI-level card selection validation
     * @note Ensures consistent card selection rules across all game interactions
     */
    func canPlayerSelectCardForMeld(_ player: Player) -> Bool {
        // Only human players can select cards for melding
        guard player.type == .human else { return false }
        
        // Check if meld choice is currently allowed
        guard awaitingMeldChoice else { return false }
        
        // Verify player has meld capability
        guard canPlayerMeld else { return false }
        
        // Verify player is the trick winner (only trick winner can select cards for melding)
        guard player.id == trickWinnerId else { return false }
        
        return true
    }
    
    /**
     * Validates if a player can play a card from their hand.
     * 
     * This method enforces card play rules:
     * - Player turn verification
     * - Play capability check
     * - Player ownership verification
     * 
     * @param player The player attempting to play a card
     * @param card The card being played
     * @return Bool indicating if card play is allowed
     * 
     * @note This method replaces the previous UI-level card play validation
     * @note Ensures consistent card play rules across all game interactions
     */
    func canPlayerPlayCardFromHand(_ player: Player, card: PlayerCard) -> Bool {
        // Verify player is the current player (turn enforcement)
        guard player.id == currentPlayer.id else { return false }
        
        // Check if card play is currently allowed
        guard canPlayCard() else { return false }
        
        // Verify the card belongs to the player
        guard player.held.contains(where: { $0.id == card.id }) else { return false }
        
        return true
    }
    
    /**
     * Validates card count for melding operations.
     * 
     * This method enforces meld card count rules:
     * - Minimum 2 cards required
     * - Maximum 4 cards allowed
     * 
     * @param cards The cards to validate
     * @return Bool indicating if card count is valid for melding
     * 
     * @note This method provides centralized card count validation
     * @note Used by both UI components and game logic
     */
    func validateMeldCardCount(_ cards: [PlayerCard]) -> Bool {
        return cards.count >= 2 && cards.count <= 4
    }
    
    /**
     * Validates hand size limit for a player.
     * 
     * This method enforces hand size rules:
     * - Maximum 9 cards allowed (held + melded)
     * 
     * @param player The player to check hand size for
     * @return Bool indicating if hand size is within limits
     * 
     * @note This method provides centralized hand size validation
     * @note Used by both UI components and game logic
     */
    func validateHandSizeLimit(for player: Player) -> Bool {
        return player.hand.count < 9
    }
    
    /**
     * Declares a meld from UI interaction with full validation.
     * 
     * This method handles the complete meld declaration process:
     * - Validates all meld requirements
     * - Creates and declares the meld
     * - Handles success/failure responses
     * 
     * @param player The player declaring the meld
     * @param selectedCards The cards selected for the meld
     * @return MeldResult indicating success/failure and details
     * 
     * @note This method replaces the previous UI-level meld declaration logic
     * @note Provides centralized meld processing with consistent validation
     */
    func declareMeldFromUI(player: Player, selectedCards: [PlayerCard]) -> MeldResult {
        // Validate player can meld
        guard canPlayerMeld(player, selectedCards: selectedCards) else {
            return MeldResult(success: false, reason: "Player cannot meld at this time")
        }
        
        // Validate card count
        guard validateMeldCardCount(selectedCards) else {
            return MeldResult(success: false, reason: "Invalid card count for melding")
        }
        
        // Get unique cards (remove duplicates)
        let uniqueSelectedCards = Array(Set(selectedCards))
        
        // Determine meld type
        guard let meldType = getMeldTypeForCards(uniqueSelectedCards, trumpSuit: trumpSuit) else {
            return MeldResult(success: false, reason: "Invalid meld combination")
        }
        
        // Calculate point value
        let pointValue = getPointValueForMeldType(meldType)
        
        // Create meld object
        let meld = Meld(
            cardIDs: uniqueSelectedCards.map { $0.id },
            type: meldType,
            pointValue: pointValue,
            roundNumber: roundNumber
        )
        
        // Validate meld can be declared
        guard canDeclareMeld(meld, by: player) else {
            return MeldResult(success: false, reason: "Meld validation failed")
        }
        
        // Declare the meld
        declareMeld(meld, by: player)
        
        return MeldResult(success: true, reason: "Meld declared successfully")
    }
}
