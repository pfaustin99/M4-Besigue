import SwiftUI

/// GameBoardContentView - Main content coordinator for the game board
/// 
/// This view handles the layout coordination and delegates to specialized components
struct GameBoardContentView: View {
    // MARK: - Dependencies
    let game: Game
    let settings: GameSettings
    let gameRules: GameRules
    let viewState: GameBoardViewState2
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section: Scoreboard and controls
            GameBoardTopSection(
                game: game,
                settings: settings,
                viewState: viewState
            )
            
            // Center section: Main game area
            GameBoardCenterSection(
                game: game,
                settings: settings,
                gameRules: gameRules,
                viewState: viewState,
                geometry: geometry
            )
            
            // Bottom section: Player hand and actions
            GameBoardBottomSection(
                game: game,
                settings: settings,
                viewState: viewState
            )
        }
        .overlay(
            // Floating action buttons
            GameBoardFloatingButtons(
                game: game,
                viewState: viewState
            ),
            alignment: .topTrailing
        )
    }
} 