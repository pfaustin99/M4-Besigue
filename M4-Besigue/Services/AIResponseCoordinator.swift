import Foundation
import Combine

// MARK: - AI Response Coordinator
class AIResponseCoordinator: ObservableObject {
    
    // MARK: - Properties
    private let aiService: AIService
    private let game: Game
    
    // MARK: - AI Position Management
    /// Stores each AI player's registered positions in the game rotation
    /// Key: Player UUID, Value: Tuple of (drawIndex, playIndex)
    private var aiPositions: [UUID: (drawIndex: Int, playIndex: Int)] = [:]
    
    // MARK: - Game State Monitoring
    /// Combine cancellables for monitoring game state changes
    private var cancellables: Set<AnyCancellable> = []
    
    /// Flag indicating whether the coordinator is actively monitoring game state
    private var isMonitoring: Bool = false
    
    /// Serial queue to keep AI decisions ordered (prevents re-entrancy races)
    private let aiQueue = DispatchQueue(label: "game.ai.queue", qos: .userInitiated)
    
    // MARK: - Initialization
    init(aiService: AIService, game: Game) {
        self.aiService = aiService
        self.game = game
    }
    
    // MARK: - Public Interface
    
    // MARK: - AI Position Registration and Monitoring
    
    /**
     * Registers AI player positions in the game rotation after cards are dealt.
     * 
     * This method captures each AI player's position in the draw and play cycles
     * so the coordinator can monitor when it's their turn to act. Positions are
     * registered based on the player's index in the players array at the time
     * of registration.
     * 
     * @note This method should be called after dealing cards when the game
     *       rotation is established but before the first trick begins.
     * @note Only AI players are registered; human players are ignored.
     * @note Positions are stored as (drawIndex, playIndex) tuples for each AI player.
     */
    func registerAIPositions() {
        // Clear any existing registrations
        aiPositions.removeAll()
        
        print("🤖 AI Response Coordinator: Starting AI position registration")
        
        // Register each AI player's position in the game rotation
        for (index, player) in game.players.enumerated() where player.type == .ai {
            aiPositions[player.id] = (drawIndex: index, playIndex: index)
            print("🤖 Registered AI \(player.name) at position \(index)")
        }
        
        print("🤖 AI positions registered: \(aiPositions)")
        
        // Start monitoring game state changes after registration
        startMonitoring()
    }
    
    /**
     * Starts monitoring game state changes to automatically trigger AI actions.
     * 
     * This method sets up Combine publishers to watch for changes in:
     * - currentDrawIndex: When it's an AI's turn to draw
     * - currentPlayIndex: When it's an AI's turn to play (with trick winner check)
     * 
     * The AI will automatically respond to these state changes without
     * requiring manual intervention.
     * 
     * @note Monitoring continues until the coordinator is deallocated or stopped.
     */
    func startMonitoring() {
        // Prevent multiple monitoring sessions
        guard !isMonitoring else {
            print("🤖 AI Response Coordinator: Monitoring already active, skipping")
            return
        }
        
        print("🤖 AI Response Coordinator: Starting game state monitoring")
        
        // 1) When the draw index changes → allow (or perform) draws (but not during initial trick)
        game.$currentDrawIndex
            .removeDuplicates()
            .filter { [weak self] _ in 
                guard let self = self else { return false }
                return !self.game.isFirstTrick 
            } // don't draw during initial trick
            .receive(on: aiQueue)
            .map { [weak self] idx in
                guard let self = self else { return (0, nil, nil, false, true) }
                return (idx,
                 self.game.players[safe: idx]?.id,
                 self.game.players[safe: idx]?.type,
                 self.game.hasDrawnForNextTrick[self.game.players[safe: idx]?.id ?? UUID(), default: false],
                 self.game.deck.isEmpty)
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] (drawIdx, playerId, playerType, hasDrawn, deckEmpty) in
                self?.handleDrawTurn(
                    drawIndex: drawIdx,
                    playerId: playerId,
                    playerType: playerType,
                    hasAlreadyDrawn: hasDrawn,
                    deckEmpty: deckEmpty
                )
            }
            .store(in: &cancellables)
        
        // 2) When the play index changes → it's someone's turn to play (AI checks trick winner first)
        game.$currentPlayIndex
            .removeDuplicates()
            .receive(on: aiQueue)
            .map { [weak self] idx in
                guard let self = self else { return (0, nil, nil, 0, -1) }
                return (idx,
                 self.game.players[safe: idx]?.id,
                 self.game.players[safe: idx]?.type,
                 self.game.currentPlayerIndex,
                 self.game.winningCardIndex ?? -1)
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] (playIdx, playerId, playerType, currentPlayerIdx, winningIdx) in
                self?.handleTurnToPlay(
                    index: playIdx,
                    playerId: playerId,
                    playerType: playerType,
                    currentPlayerIndex: currentPlayerIdx,
                    winningCardIndex: winningIdx
                )
            }
            .store(in: &cancellables)
        
        isMonitoring = true
        print("🤖 AI Response Coordinator: Game state monitoring active")
    }
    
    /**
     * Stops monitoring game state changes and cleans up resources.
     * 
     * This method cancels all active Combine subscriptions and resets
     * the monitoring state. It's useful for cleanup or when the game
     * needs to pause AI processing.
     * 
     * @note This method can be called multiple times safely.
     * @note All cancellables are automatically cleaned up.
     */
    func stopMonitoring() {
        print("🤖 AI Response Coordinator: Stopping game state monitoring")
        
        // Cancel all active subscriptions
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        isMonitoring = false
        print("🤖 AI Response Coordinator: Game state monitoring stopped")
    }
    
    // MARK: - AI Action Handlers
    
    /**
     * Handles draw turns when currentDrawIndex changes.
     * 
     * This method is called when it's someone's turn to draw and determines
     * if an AI player should draw a card.
     * 
     * @param drawIndex The index of the player whose turn it is to draw
     * @param playerId The ID of the player at the draw index
     * @param playerType The type of player (human or AI)
     * @param hasAlreadyDrawn Whether the player has already drawn for this trick
     * @param deckEmpty Whether the draw pile is empty
     */
    private func handleDrawTurn(
        drawIndex: Int,
        playerId: UUID?,
        playerType: PlayerType?,
        hasAlreadyDrawn: Bool,
        deckEmpty: Bool
    ) {
        print("🤖 Handling draw turn - Index: \(drawIndex), Player: \(playerType?.rawValue ?? "nil")")
        
        // Check if AI needs to draw
        if let playerId = playerId,
           let playerType = playerType,
           playerType == .ai,
           let aiPosition = aiPositions[playerId],
           drawIndex == aiPosition.drawIndex,
           !hasAlreadyDrawn,
           !deckEmpty {
            
            if let drawAIPlayer = game.players.first(where: { $0.id == playerId }) {
                print("🤖 AI \(drawAIPlayer.name) needs to draw - it's their draw turn")
                
                // AI draws a card
                print("🤖 AI \(drawAIPlayer.name) executing draw sequence")
                drawAIPlayer.makeAIDecision(in: game, aiService: aiService)
            }
        }
    }
    
    /**
     * Handles play turns when currentPlayIndex changes.
     * 
     * This method is called when it's someone's turn to play and determines
     * if an AI player should play a card. The AI ALWAYS checks if it's the
     * trick winner before taking any action.
     * 
     * @param index The index of the player whose turn it is to play
     * @param playerId The ID of the player at the play index
     * @param playerType The type of player (human or AI)
     * @param currentPlayerIndex The current player index for validation
     * @param winningCardIndex The index of the winning card (if any)
     */
    private func handleTurnToPlay(
        index: Int,
        playerId: UUID?,
        playerType: PlayerType?,
        currentPlayerIndex: Int,
        winningCardIndex: Int
    ) {
        print("🤖 Handling turn to play - Index: \(index), Player: \(playerType?.rawValue ?? "nil"), Current: \(currentPlayerIndex), Winning: \(winningCardIndex)")
        
        // Check if AI can play
        if let playerId = playerId,
           let playerType = playerType,
           playerType == .ai,
           let aiPosition = aiPositions[playerId],
           index == aiPosition.playIndex {
            
            // CRITICAL: Only allow AI to play if it's actually the current player
            if index == currentPlayerIndex {
                if let playAIPlayer = game.players.first(where: { $0.id == playerId }) {
                    
                    // 🎯 ALWAYS check if AI is the trick winner first
                    let isTrickWinner = winningCardIndex == index
                    
                    if isTrickWinner {
                        print("🤖 AI \(playAIPlayer.name) is the trick winner - handling trick resolution sequence")
                        
                        // Trick winner sequence: Meld (optional) → Draw → Play
                        // 1. Check if AI can meld
                        if game.canPlayerMeld {
                            print("🤖 AI \(playAIPlayer.name) evaluating melding opportunities")
                            // AI will handle melding in makeAIDecision
                        }
                        
                        // 2. AI draws a card (unless it's the first trick or deck is empty)
                        if !game.isFirstTrick && !game.deck.isEmpty {
                            print("🤖 AI \(playAIPlayer.name) drawing card as trick winner")
                            // AI will handle drawing in makeAIDecision
                        }
                        
                        // 3. AI plays a card
                        print("🤖 AI \(playAIPlayer.name) executing play sequence as trick winner")
                        playAIPlayer.makeAIDecision(in: game, aiService: aiService)
                        
                    } else {
                        // Not trick winner - normal play turn
                        print("🤖 AI \(playAIPlayer.name) is not the trick winner - normal play turn")
                        
                        // Check if AI has drawn (or can skip drawing in first trick)
                        let hasDrawn = game.hasDrawnForNextTrick[playerId, default: false]
                        let canSkipDraw = game.isFirstTrick || game.deck.isEmpty
                        
                        if hasDrawn || canSkipDraw {
                            print("🤖 AI \(playAIPlayer.name) can play - it's their play turn")
                            
                            // AI plays a card
                            print("🤖 AI \(playAIPlayer.name) executing play sequence")
                            playAIPlayer.makeAIDecision(in: game, aiService: aiService)
                        } else {
                            print("🤖 AI \(playAIPlayer.name) cannot play yet - must draw first")
                        }
                    }
                }
            } else {
                print("🤖 AI at play index \(index) is not the current player (\(currentPlayerIndex)) - skipping play")
            }
        }
    }
}

// MARK: - Array Safe Access Extension
extension Array {
    /**
     * Safely accesses an array element at the specified index.
     * 
     * This extension provides a safe way to access array elements without
     * causing index out of bounds crashes. Returns nil if the index is invalid.
     * 
     * @param index The index to access
     * @return The element at the index, or nil if the index is out of bounds
     * 
     * @note This is particularly useful for game logic where indices may
     *       change dynamically and bounds checking is critical.
     */
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
