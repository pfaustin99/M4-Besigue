import SwiftUI

struct ContentView: View {
    @StateObject private var settings = GameSettings(playerCount: 2)
    @StateObject private var game: Game
    
    init() {
        // Initialize with error handling
        let tempSettings = GameSettings(playerCount: 2)
        let tempGame = Game(playerCount: 2, isOnline: false, aiDifficulty: .medium, settings: tempSettings)
        
        self._settings = StateObject(wrappedValue: tempSettings)
        self._game = StateObject(wrappedValue: tempGame)
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
                            game.startNewGame()
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.headline)
                    }
                    .padding()
                } else {
                    // Show the main game board
                    GameBoardView(game: game, settings: settings)
                }
            }
            .navigationTitle("M4-Bésigue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Game") {
                        game.startNewGame()
                    }
                }
            }
        }
        .onAppear {
            // Don't auto-start the game - let user click the button
            print("ContentView appeared")
        }
    }
}

#Preview {
    ContentView()
}
