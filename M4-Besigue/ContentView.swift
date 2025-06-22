import SwiftUI

struct ContentView: View {
    @StateObject private var game = Game(playerCount: 2)
    
    var body: some View {
        NavigationView {
            GameBoardView(game: game)
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
            // Start the game when the view appears
            if game.currentPhase == .setup {
                game.startNewGame()
            }
        }
    }
}

#Preview {
    ContentView()
}
