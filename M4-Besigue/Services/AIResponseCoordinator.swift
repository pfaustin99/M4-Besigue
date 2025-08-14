import Foundation

// MARK: - AI Response Coordinator
class AIResponseCoordinator: ObservableObject {
    
    // MARK: - AI Turn State Management
    enum AITurnState {
        case waiting
        case drawing
        case decidingMeld
        case playingCard
        case completed
    }
    
    // MARK: - AI Timing Configuration
    struct AITimingConfig {
        let thinkTime: TimeInterval
        let drawDelay: TimeInterval
        let playDelay: TimeInterval
        let meldDelay: TimeInterval
        
        static let defaultConfig = AITimingConfig(
            thinkTime: 0.5,
            drawDelay: 0.8,
            playDelay: 1.2,
            meldDelay: 1.0
        )
        
        static let fastConfig = AITimingConfig(
            thinkTime: 0.2,
            drawDelay: 0.4,
            playDelay: 0.6,
            meldDelay: 0.5
        )
        
        static let slowConfig = AITimingConfig(
            thinkTime: 1.0,
            drawDelay: 1.5,
            playDelay: 2.0,
            meldDelay: 1.5
        )
    }
    
    // MARK: - AI Personality
    struct AIPersonality {
        let difficulty: AIService.Difficulty
        let aggressiveness: Double // 0.0 to 1.0
        let riskTolerance: Double // 0.0 to 1.0
        let meldStrategy: MeldStrategy
        
        enum MeldStrategy {
            case aggressive // Declare melds early
            case conservative // Wait for high-value melds
            case balanced // Mix of both
        }
        
        static let defaultPersonality = AIPersonality(
            difficulty: .medium,
            aggressiveness: 0.5,
            riskTolerance: 0.5,
            meldStrategy: .balanced
        )
    }
    
    // MARK: - Properties
    private let aiService: AIService
    private let game: Game
    
    @Published var currentAITurnState: AITurnState = .waiting
    @Published var currentAIPlayer: Player?
    @Published var aiTurnProgress: Double = 0.0
    
    private var aiTurnQueue: [UUID] = []
    internal var aiTimingConfig: AITimingConfig
    private var aiPersonalities: [UUID: AIPersonality]
    private var aiResponseWorkItems: [UUID: DispatchWorkItem] = [:]
    
    // MARK: - Initialization
    init(aiService: AIService, game: Game, timingConfig: AITimingConfig = .defaultConfig) {
        self.aiService = aiService
        self.game = game
        self.aiTimingConfig = timingConfig
        self.aiPersonalities = [:]
        
        // Set default personalities for all AI players
        setupDefaultPersonalities()
    }
    
    // MARK: - Public Interface
    
    /// Main entry point for AI responses - called whenever game state changes
    func handleAIResponseIfNeeded() {
        print("🤖 AI Response Coordinator: handleAIResponseIfNeeded called")
        print("🤖 DEBUG: Current player: \(game.currentPlayer.name) (type: \(game.currentPlayer.type))")
        print("🤖 DEBUG: Current draw index: \(game.currentDrawIndex)")
        print("🤖 DEBUG: Current play index: \(game.currentPlayIndex)")
        print("🤖 DEBUG: Current player index: \(game.currentPlayerIndex)")
        
        // Only proceed if current player is AI
        guard game.currentPlayer.type == .ai else { 
            print("🤖 DEBUG: Current player is not AI, returning")
            return 
        }
        
        // Check if AI is already processing a turn
        guard currentAITurnState == .waiting else { 
            print("🤖 DEBUG: AI is already processing a turn (state: \(currentAITurnState)), returning")
            return 
        }
        
        print("🤖 AI Response Coordinator: Handling AI turn for \(game.currentPlayer.name)")
        
        // Start AI turn processing
        startAITurn(for: game.currentPlayer)
    }
    
    /// Schedule an AI response for a specific player
    func scheduleAIResponse(for player: Player) {
        guard player.type == .ai else { return }
        
        // Cancel any existing response for this player
        cancelAIResponse(for: player)
        
        // Add to queue if not already there
        if !aiTurnQueue.contains(player.id) {
            aiTurnQueue.append(player.id)
        }
        
        print("🤖 AI Response Coordinator: Scheduled response for \(player.name)")
    }
    
    /// Cancel AI response for a specific player
    func cancelAIResponse(for player: Player) {
        // Cancel any pending work item
        if let workItem = aiResponseWorkItems[player.id] {
            workItem.cancel()
            aiResponseWorkItems.removeValue(forKey: player.id)
        }
        
        // Remove from queue
        aiTurnQueue.removeAll { $0 == player.id }
        
        print("🤖 AI Response Coordinator: Cancelled response for \(player.name)")
    }
    
    /// Update AI personality for a specific player
    func updateAIPersonality(for player: Player, personality: AIPersonality) {
        aiPersonalities[player.id] = personality
        print("🤖 AI Response Coordinator: Updated personality for \(player.name) to \(personality.difficulty)")
    }
    
    /// Get current AI personality for a player
    func getAIPersonality(for player: Player) -> AIPersonality {
        return aiPersonalities[player.id, default: .defaultPersonality]
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultPersonalities() {
        for player in game.players where player.type == .ai {
            aiPersonalities[player.id] = .defaultPersonality
        }
    }
    
    private func startAITurn(for player: Player) {
        
        currentAIPlayer = player
        currentAITurnState = .drawing
        aiTurnProgress = 0.0
        
        print("🤖 AI Response Coordinator: Starting AI turn for \(player.name)")
        print("🤖 DEBUG: AI turn state set to: \(currentAITurnState)")
        
        // Process AI turn based on current game state
        processAITurn(for: player, in: game)
    }
    
    private func processAITurn(for player: Player, in game: Game) {
        print("🤖 AI Response Coordinator: processAITurn called for \(player.name)")
        
        // Check if AI needs to draw a card first
        let isCurrentDrawPlayer = game.currentDrawIndex == game.players.firstIndex(where: { $0.id == player.id })
        let hasNotDrawn = !game.hasDrawnForNextTrick[player.id, default: false]
        let canDraw = !game.deck.isEmpty && game.validateHandSizeLimit(for: player)
        
        print("🤖 AI Response Coordinator: Debug for \(player.name):")
        print("   isCurrentDrawPlayer: \(isCurrentDrawPlayer)")
        print("   hasNotDrawn: \(hasNotDrawn)")
        print("   canDraw: \(canDraw)")
        print("   currentDrawIndex: \(game.currentDrawIndex)")
        print("   player index: \(game.players.firstIndex(where: { $0.id == player.id }) ?? -1)")
        print("   deck empty: \(game.deck.isEmpty)")
        print("   hand size limit valid: \(game.validateHandSizeLimit(for: player))")
        
        if isCurrentDrawPlayer && hasNotDrawn && canDraw {
            print("🤖 AI Response Coordinator: \(player.name) needs to draw a card - calling handleAIDraw")
            handleAIDraw(for: player, in: game)
        } else if game.canPlayerMeld {
            print("🤖 AI Response Coordinator: \(player.name) can meld - calling handleAIMeld")
            handleAIMeld(for: player, in: game)
        } else {
            print("🤖 AI Response Coordinator: \(player.name) needs to play a card - calling handleAIPlay")
            handleAIPlay(for: player, in: game)
        }
    }
    
    private func handleAIDraw(for player: Player, in game: Game) {
        currentAITurnState = .drawing
        
        // Simulate AI thinking time
        let workItem = DispatchWorkItem { [weak self] in
            self?.executeAIDraw(for: player, in: game)
        }
        
        aiResponseWorkItems[player.id] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + aiTimingConfig.drawDelay, execute: workItem)
        
        print("🤖 AI Response Coordinator: Scheduled draw for \(player.name) in \(aiTimingConfig.drawDelay)s")
    }
    
    private func executeAIDraw(for player: Player, in game: Game) {
        
        print("🤖 AI Response Coordinator: Executing draw for \(player.name)")
        
        // AI draws a card
        if let card = game.deck.drawCard() {
            player.addCards([card])
            game.hasDrawnForNextTrick[player.id] = true
            print("🤖 AI \(player.name) drew \(card.displayName)")
            
            // Post notification for view state to trigger draw animation
            NotificationCenter.default.post(
                name: .cardDrawn,
                object: card
            )
            
            // Check if ALL players have drawn for this trick
            let allHaveDrawn = game.players.allSatisfy { game.hasDrawnForNextTrick[$0.id, default: false] }
            
            if allHaveDrawn {
                print("🔄 All players have drawn - starting new trick")
                // All players have drawn, start new trick
                game.startNewTrick()
            } else {
                print("🔄 Not all players have drawn yet - continuing draw cycle")
                // Move to next player who needs to draw
                game.currentDrawIndex = (game.currentDrawIndex + 1) % game.playerCount
                
                // Only move currentPlayerIndex if the current player has already drawn
                if game.hasDrawnForNextTrick[game.currentPlayer.id, default: false] {
                    // Current player has drawn, they can play - don't change currentPlayerIndex
                    print("🔄 \(game.currentPlayer.name) has drawn and can now play - keeping turn")
                    
                    // Continue with AI turn (now they can play)
                    DispatchQueue.main.asyncAfter(deadline: .now() + aiTimingConfig.thinkTime) {
                        self.processAITurn(for: player, in: game)
                    }
                } else {
                    // Current player hasn't drawn yet, get next player who needs to draw
                    let nextDrawPlayer = game.players[game.currentDrawIndex]
                    nextDrawPlayer.isCurrentPlayer = true
                    
                    // Clear previous player's current status
                    for (index, player) in game.players.enumerated() {
                        if index != game.currentDrawIndex {
                            player.isCurrentPlayer = false
                        }
                    }
                    
                    print("🔄 Next draw player: \(nextDrawPlayer.name) (index: \(game.currentDrawIndex))")
                    
                    // If next draw player is AI, trigger AI turn
                    if nextDrawPlayer.type == .ai {
                        DispatchQueue.main.asyncAfter(deadline: .now() + aiTimingConfig.thinkTime) {
                            self.handleAIResponseIfNeeded()
                        }
                    }
                }
            }
        }
        
        // Clean up
        aiResponseWorkItems.removeValue(forKey: player.id)
        currentAITurnState = .waiting
        currentAIPlayer = nil
    }
    
    private func handleAIMeld(for player: Player, in game: Game) {
        currentAITurnState = .decidingMeld
        
        // Simulate AI thinking time for meld decisions
        let workItem = DispatchWorkItem { [weak self] in
            self?.executeAIMeld(for: player, in: game)
        }
        
        aiResponseWorkItems[player.id] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + aiTimingConfig.meldDelay, execute: workItem)
        
        print("🤖 AI Response Coordinator: Scheduled meld decision for \(player.name) in \(aiTimingConfig.meldDelay)s")
    }
    
    private func executeAIMeld(for player: Player, in game: Game) {
        print("🤖 AI Response Coordinator: Executing meld decision for \(player.name)")
        
        // AI decides on melds
        let meldsToDeclare = aiService.decideMeldsToDeclare(for: player, in: game)
        for meld in meldsToDeclare {
            game.declareMeld(meld, by: player)
        }
        
        // After melding, AI needs to play a card
        DispatchQueue.main.asyncAfter(deadline: .now() + aiTimingConfig.thinkTime) {
            self.handleAIPlay(for: player, in: game)
        }
    }
    
    private func handleAIPlay(for player: Player, in game: Game) {
        currentAITurnState = .playingCard
        
        // Simulate AI thinking time for card selection
        let workItem = DispatchWorkItem { [weak self] in
            self?.executeAIPlay(for: player, in: game)
        }
        
        aiResponseWorkItems[player.id] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + aiTimingConfig.playDelay, execute: workItem)
        
        print("🤖 AI Response Coordinator: Scheduled card play for \(player.name) in \(aiTimingConfig.playDelay)s")
    }
    
    private func executeAIPlay(for player: Player, in game: Game) {
        print("🤖 AI Response Coordinator: Executing card play for \(player.name)")
        
        // AI chooses and plays a card
        if let cardToPlay = aiService.chooseCardToPlay(for: player, in: game) {
            game.playCard(cardToPlay, from: player)
        }
        
        // Clean up
        aiResponseWorkItems.removeValue(forKey: player.id)
        currentAITurnState = .completed
        currentAIPlayer = nil
        
        print("🤖 AI Response Coordinator: Completed AI turn for \(player.name)")
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    func debugAIState() {
        print("🤖 AI Response Coordinator Debug:")
        print("   Current AI player: \(currentAIPlayer?.name ?? "None")")
        print("   Current AI turn state: \(currentAITurnState)")
        print("   AI turn progress: \(aiTurnProgress)")
        print("   AI turn queue: \(aiTurnQueue)")
        print("   Pending work items: \(aiResponseWorkItems.keys)")
        
        print("   Current player: \(game.currentPlayer.name)")
        print("   Game phase: \(game.currentPhase)")
        print("   Must draw: \(game.mustDrawCard)")
        print("   Can meld: \(game.canPlayerMeld)")
    }
    #endif
}

// Notification names are already defined in NetworkService.swift
