import Foundation
import Combine

// MARK: - AI Response Coordinator
class AIResponseCoordinator: ObservableObject {
    
    // MARK: - Properties
    
    /// The game instance being monitored
    private let game: Game
    
    /// The AI service for strategic decision-making
    private let aiService: AIService
    
    /// Set of cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Flag indicating if monitoring is active
    private var isMonitoring = false
    
    /// Serial queue for processing AI actions sequentially
    private let aiQueue = DispatchQueue(label: "game.ai.queue", qos: .userInitiated)
    
    // MARK: - Initialization
    init(aiService: AIService, game: Game) {
        self.aiService = aiService
        self.game = game
    }
    
    // MARK: - Public Interface
    
    /**
     * Starts monitoring game state changes to automatically trigger AI actions.
     * 
     * This method sets up Combine publishers to watch for changes in:
     * - currentDrawIndex: When it's an AI's turn to draw
     * - currentPlayIndex: When it's an AI's turn to play
     * 
     * Separate monitoring ensures each action is triggered exactly once
     * without duplicate notifications or overlapping triggers.
     * 
     * @note Monitoring continues until the coordinator is deallocated or stopped.
     */
    func startMonitoring() {
        // Prevent multiple monitoring sessions
        guard !isMonitoring else {
            print("🤖 AI Response Coordinator: Monitoring already active, skipping")
            return
        }
        
        print("🤖 AI Response Coordinator: Starting separate game state monitoring")
        
        // 1) Draw monitoring (separate, always works)
        game.$currentDrawIndex
            .removeDuplicates()
            .filter { [weak self] _ in
                guard let self = self else { return false }
                return !self.game.isFirstTrick
            }
            .receive(on: aiQueue)
            .sink { [weak self] drawIndex in
                self?.handleAIDrawTurn(index: drawIndex)
            }
            .store(in: &cancellables)
        
        // 2) Play monitoring (separate, always works)
        game.$currentPlayIndex
            .removeDuplicates()
            .receive(on: aiQueue)
            .sink { [weak self] playIndex in
                self?.handleAIPlayTurn(index: playIndex)
            }
            .store(in: &cancellables)
        
        // 3) Trick winner monitoring (separate, always works)
        game.$winningCardIndex
            .compactMap { $0 }  // Filter out nil values
            .removeDuplicates()
            .receive(on: aiQueue)
            .sink { [weak self] winningIndex in
                self?.handleTrickWinner(index: winningIndex)
            }
            .store(in: &cancellables)
        
        isMonitoring = true
        print("🤖 AI Response Coordinator: Separate game state monitoring active (draw + play + trick winner)")
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
     * Handles turn changes when currentPlayerIndex changes.
     * 
     * This method is called when it's an AI's turn to act and notifies
     * the specific AI player at that index to make their decision.
     * 
     * @param index The index of the player whose turn it is to act
     */
    private func handleAITurn(index: Int) {
        // Validate bounds first
        guard index >= 0 && index < game.players.count else {
            print("🤖 ERROR: Player index \(index) out of bounds (0-\(game.players.count-1))")
            return
        }
        
        // Check if AI exists at that index
        let player = game.players[index]
        guard player.type == .ai else { return }
        
        print("🤖 AI \(player.name) at index \(index) notified of turn")
        
        // Notify the specific AI to make their decision
        player.makeAIDecision(in: game, aiService: aiService)
    }
    
    /**
     * Handles draw turns when currentDrawIndex changes.
     * 
     * This method is called when it's someone's turn to draw and notifies
     * the specific AI player at that index to make their draw decision.
     * 
     * @param index The index of the player whose turn it is to draw
     */
    private func handleAIDrawTurn(index: Int) {
        // Validate bounds first
        guard index >= 0 && index < game.players.count else {
            print("🤖 ERROR: Draw index \(index) out of bounds (0-\(game.players.count-1))")
            return
        }
        
        // Check if AI exists at that index
        let player = game.players[index]
        guard player.type == .ai else { return }
        
        print("🤖 AI \(player.name) at index \(index) notified of draw turn")
        
        // Notify the specific AI to make their decision
        player.makeAIDecision(in: game, aiService: aiService)
    }
    
    /**
     * Handles play turns when currentPlayIndex changes.
     * 
     * This method is called when it's someone's turn to play and notifies
     * the specific AI player at that index to make their play decision.
     * 
     * @param index The index of the player whose turn it is to play
     */
    private func handleAIPlayTurn(index: Int) {
        // Validate bounds first
        guard index >= 0 && index < game.players.count else {
            print("🤖 ERROR: Play index \(index) out of bounds (0-\(game.players.count-1))")
            return
        }
        
        // Check if AI exists at that index
        let player = game.players[index]
        guard player.type == .ai else { return }
        
        print("🤖 AI \(player.name) at index \(index) notified of play turn")
        
        // Notify the specific AI to make their decision
        player.makeAIDecision(in: game, aiService: aiService)
    }
    
    /**
     * Handles trick winner notifications when winningCardIndex changes.
     * 
     * This method is called when an AI wins a trick and notifies
     * the specific AI player at that index to make their decision.
     * 
     * @param index The index of the player who won the trick
     */
    private func handleTrickWinner(index: Int) {
        // Validate bounds first
        guard index >= 0 && index < game.players.count else {
            print("🤖 ERROR: Winning index \(index) out of bounds (0-\(game.players.count-1))")
            return
        }
        
        // Check if AI exists at that index
        let player = game.players[index]
        guard player.type == .ai else { return }
        
        print("🤖 AI \(player.name) at index \(index) notified of trick win")
        
        // Notify the specific AI to make their decision
        player.makeAIDecision(in: game, aiService: aiService)
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
