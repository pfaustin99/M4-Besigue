import SwiftUI

struct ContentView: View {
    @StateObject private var settings = GameSettings()
    @StateObject private var gameRules = GameRules()
    @State private var game: Game
    @State private var showingGameSettings = false
    
    init() {
        // Initialize with error handling
        let tempSettings = GameSettings()
        let tempGameRules = GameRules()
        let tempGame = Game(gameRules: tempGameRules)
        
        self._settings = StateObject(wrappedValue: tempSettings)
        self._gameRules = StateObject(wrappedValue: tempGameRules)
        self._game = State(initialValue: tempGame)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if game.currentPhase == .setup {
                    // Show a simple start screen first
                    VStack(spacing: 20) {
                        Text("M4-Bésigue")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("A traditional card game")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Start New Game") {
                            showingGameSettings = true
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.headline)
                    }
                    .padding()
                } else {
                    // Show the main game board
                    GameBoardView(game: game, settings: settings, gameRules: gameRules)
                }
            }
            .navigationTitle("M4-Bésigue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Game") {
                        showingGameSettings = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingGameSettings) {
            GameSettingsView(gameRules: gameRules, onSave: {
                // Apply the settings and start new game
                startNewGameWithRules()
            })
        }
        .onAppear {
            // Auto-start the game for testing
            print("ContentView appeared - auto-starting game")
            startNewGameWithRules()
        }
    }
    
    private func startNewGameWithRules() {
        // Apply game rules to the settings object
        settings.playerCount = gameRules.playerCount
        settings.handSize = gameRules.handSize
        settings.playDirection = gameRules.playDirection
        settings.gameLevel = gameRules.gameLevel
        
        // Apply scoring rules
        settings.besiguePoints = gameRules.besiguePoints
        settings.royalMarriagePoints = gameRules.royalMarriagePoints
        settings.commonMarriagePoints = gameRules.commonMarriagePoints
        settings.fourAcesPoints = gameRules.fourAcesPoints
        settings.fourKingsPoints = gameRules.fourKingsPoints
        settings.fourQueensPoints = gameRules.fourQueensPoints
        settings.fourJacksPoints = gameRules.fourJacksPoints
        settings.fourJokersPoints = gameRules.fourJokersPoints
        settings.sequencePoints = gameRules.sequencePoints
        settings.trumpFourAcesMultiplier = gameRules.trumpFourAcesMultiplier
        settings.trumpFourKingsMultiplier = gameRules.trumpFourKingsMultiplier
        settings.trumpFourQueensMultiplier = gameRules.trumpFourQueensMultiplier
        settings.trumpFourJacksMultiplier = gameRules.trumpFourJacksMultiplier
        settings.trumpSequenceMultiplier = gameRules.trumpSequenceMultiplier
        settings.brisqueValue = gameRules.brisqueValue
        settings.finalTrickBonus = gameRules.finalTrickBonus
        settings.trickWithSevenTrumpPoints = gameRules.trickWithSevenTrumpPoints
        
        // Apply penalty rules
        settings.penalty = gameRules.penalty
        settings.penaltyBelow100 = gameRules.penaltyBelow100
        settings.penaltyFewBrisques = gameRules.penaltyFewBrisques
        settings.penaltyOutOfTurn = gameRules.penaltyOutOfTurn
        settings.brisqueCutoff = gameRules.brisqueCutoff
        settings.minScoreForBrisques = gameRules.minScoreForBrisques
        settings.minBrisques = gameRules.minBrisques
        
        // Apply animation timing to settings
        settings.cardPlayDelay = gameRules.cardPlayDelay
        settings.cardPlayDuration = gameRules.cardPlayDuration
        settings.dealerDeterminationDelay = gameRules.dealerDeterminationDelay
        
        // Apply trick area size to settings (for backward compatibility)
        // Note: This will be removed once Game model uses GameRules directly
        settings.trickAreaSize = gameRules.trickAreaSize
        
        // Create a new game with the updated game rules
        let newGame = Game(gameRules: gameRules)
        
        // Replace the current game
        self.game = newGame
        
        // Start the new game
        game.startNewGame()
    }
}

#Preview {
    ContentView()
}
