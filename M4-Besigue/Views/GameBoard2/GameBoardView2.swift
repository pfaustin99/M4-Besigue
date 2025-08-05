import SwiftUI

/// GameBoardView2 - A clean, modular coordinator for the game board
/// 
/// This view acts as a coordinator that delegates to specialized components:
/// - Layout management
/// - Game state coordination  
/// - Animation coordination
/// - UI component orchestration
struct GameBoardView2: View {
    // MARK: - Dependencies
    @ObservedObject var game: Game
    @ObservedObject var settings: GameSettings
    @ObservedObject var gameRules: GameRules
    let onEndGame: () -> Void
    
    // MARK: - State Management
    @StateObject private var viewState = GameBoardViewState2()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                GameBoardBackgroundView()
                
                // Main game content
                GameBoardContentView(
                    game: game,
                    settings: settings,
                    gameRules: gameRules,
                    viewState: viewState,
                    geometry: geometry
                )
            }
        }
        .ignoresSafeArea(.container, edges: [])
        .sheet(isPresented: $viewState.showingMeldOptions) {
            MeldOptionsView2(
                game: game,
                settings: settings,
                selectedCards: $viewState.selectedCards
            )
        }
        .sheet(isPresented: $viewState.showingSettings) {
            SettingsView(settings: settings)
        }
        .sheet(isPresented: $viewState.showingBadgeLegend) {
            BadgeLegendView2()
        }
    }
}

// MARK: - Preview
#if DEBUG
struct GameBoardView2_Previews: PreviewProvider {
    static var previews: some View {
        GameBoardView2(
            game: Game(gameRules: GameRules()),
            settings: GameSettings(),
            gameRules: GameRules(),
            onEndGame: {}
        )
    }
}
#endif 