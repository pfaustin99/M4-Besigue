import XCTest
@testable import M4_Besigue

class AIResponseCoordinatorTests: XCTestCase {
    
    var game: Game!
    var aiService: AIService!
    var aiResponseCoordinator: AIResponseCoordinator!
    
    override func setUp() {
        super.setUp()
        
        // Create a simple game configuration
        let gameRules = GameRules()
        
        // Create player configurations
        let humanConfig = PlayerConfiguration(name: "Human", type: .human, position: 0)
        let aiConfig = PlayerConfiguration(name: "AI Player", type: .ai, position: 1)
        gameRules.playerConfigurations = [humanConfig, aiConfig]
        
        // Create game
        game = Game(gameRules: gameRules)
        game.initializeFromConfiguration()
        
        // Create AI service and coordinator
        aiService = AIService(difficulty: .medium)
        aiResponseCoordinator = AIResponseCoordinator(aiService: aiService, game: game)
    }
    
    override func tearDown() {
        game = nil
        aiService = nil
        aiResponseCoordinator = nil
        super.tearDown()
    }
    
    func testAIResponseCoordinatorInitialization() {
        // Test that the coordinator is properly initialized
        XCTAssertNotNil(aiResponseCoordinator)
        XCTAssertEqual(aiResponseCoordinator.currentAITurnState, .waiting)
        XCTAssertNil(aiResponseCoordinator.currentAIPlayer)
        XCTAssertEqual(aiResponseCoordinator.aiTurnProgress, 0.0)
    }
    
    func testAIResponseCoordinatorWithHumanPlayer() {
        // Test that the coordinator doesn't respond when current player is human
        game.currentPlayerIndex = 0 // Human player
        
        // This should not trigger any AI response
        aiResponseCoordinator.handleAIResponseIfNeeded()
        
        XCTAssertEqual(aiResponseCoordinator.currentAITurnState, .waiting)
        XCTAssertNil(aiResponseCoordinator.currentAIPlayer)
    }
    
    func testAIResponseCoordinatorWithAIPlayer() {
        // Test that the coordinator responds when current player is AI
        game.currentPlayerIndex = 1 // AI player
        
        // This should trigger AI response
        aiResponseCoordinator.handleAIResponseIfNeeded()
        
        // The AI should start processing
        XCTAssertNotEqual(aiResponseCoordinator.currentAITurnState, .waiting)
        XCTAssertNotNil(aiResponseCoordinator.currentAIPlayer)
        XCTAssertEqual(aiResponseCoordinator.currentAIPlayer?.name, "AI Player")
    }
    
    func testAIPersonalityManagement() {
        // Test AI personality management
        let player = game.players[1] // AI player
        
        let personality = AIResponseCoordinator.AIPersonality(
            difficulty: .hard,
            aggressiveness: 0.8,
            riskTolerance: 0.7,
            meldStrategy: .aggressive
        )
        
        aiResponseCoordinator.updateAIPersonality(for: player, personality: personality)
        
        let retrievedPersonality = aiResponseCoordinator.getAIPersonality(for: player)
        XCTAssertEqual(retrievedPersonality.difficulty, .hard)
        XCTAssertEqual(retrievedPersonality.aggressiveness, 0.8)
        XCTAssertEqual(retrievedPersonality.riskTolerance, 0.7)
        XCTAssertEqual(retrievedPersonality.meldStrategy, .aggressive)
    }
    
    func testAITimingConfiguration() {
        // Test AI timing configuration
        let fastConfig = AIResponseCoordinator.AITimingConfig.fastConfig
        
        let fastCoordinator = AIResponseCoordinator(
            aiService: aiService,
            game: game,
            timingConfig: fastConfig
        )
        
        XCTAssertEqual(fastCoordinator.aiTimingConfig.thinkTime, 0.2)
        XCTAssertEqual(fastCoordinator.aiTimingConfig.drawDelay, 0.4)
        XCTAssertEqual(fastCoordinator.aiTimingConfig.playDelay, 0.6)
        XCTAssertEqual(fastCoordinator.aiTimingConfig.meldDelay, 0.5)
    }
    
    func testAITurnStateTransitions() {
        // Test AI turn state transitions
        game.currentPlayerIndex = 1 // AI player
        
        // Start AI turn
        aiResponseCoordinator.handleAIResponseIfNeeded()
        
        // AI should be in a processing state
        XCTAssertNotEqual(aiResponseCoordinator.currentAITurnState, .waiting)
        XCTAssertNotNil(aiResponseCoordinator.currentAIPlayer)
        
        // For now, just verify the initial state transition works
        // The complete AI turn flow will be tested in integration tests
        XCTAssertTrue(true)
    }
    
    #if DEBUG
    func testDebugAIState() {
        // Test debug method
        game.currentPlayerIndex = 1 // AI player
        
        // This should not crash
        aiResponseCoordinator.debugAIState()
        
        // Test passes if no crash occurs
        XCTAssertTrue(true)
    }
    #endif
}
