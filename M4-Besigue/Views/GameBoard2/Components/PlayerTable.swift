
import SwiftUI

enum TablePosition {
    case bottom, right, top, left
}

struct PlayerTable: View {
    let player: Player
    let position: TablePosition
    let isCurrentTurn: Bool
    let isHumanPlayer: Bool
    let geometry: GeometryProxy
    let game: Game
    let viewState: GameBoardViewState2

    var body: some View {
        ZStack {
            // Main player content with proper meld positioning
            meldRowPosition(for: position)
                .rotationEffect(rotation(for: position))
            
            // Floating player name - always upright, positioned outside rotation
            GamePlayerNameView(
                player: player,
                isCurrentTurn: isCurrentTurn,
                allPlayers: game.players
            )
            .offset(nameOffset(for: position))
        }
    }

    // MARK: - Layout-Aware Meld Positioning
    @ViewBuilder
    private func meldRowPosition(for position: TablePosition) -> some View {
        let isLandscape = geometry.size.width > geometry.size.height
        
        switch position {
        case .bottom:
            // Bottom player: melds above held cards (towards trick area)
            VStack(spacing: isLandscape ? 6 : 4) {
                GameBoardMeldRowView(
                    player: player, 
                    isHuman: isHumanPlayer, 
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
                GamePlayerHandView(
                    player: player,
                    isHuman: isHumanPlayer,
                    isCurrentTurn: isCurrentTurn,
                    angle: 0,
                    isHorizontal: true,
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
            }
        case .top:
            // Top player: melds below held cards (towards trick area)
            VStack(spacing: isLandscape ? 6 : 4) {
                GamePlayerHandView(
                    player: player,
                    isHuman: isHumanPlayer,
                    isCurrentTurn: isCurrentTurn,
                    angle: 0,
                    isHorizontal: true,
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
                GameBoardMeldRowView(
                    player: player, 
                    isHuman: isHumanPlayer, 
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
            }
        case .right:
            // Right player: melds left of held cards (towards trick area)
            if isLandscape {
                // iPad landscape: use HStack for left-to-right layout
                HStack(spacing: 6) {
                    GameBoardMeldRowView(
                        player: player, 
                        isHuman: isHumanPlayer, 
                        geometry: geometry,
                        game: game,
                        viewState: viewState
                    )
                    GamePlayerHandView(
                        player: player,
                        isHuman: isHumanPlayer,
                        isCurrentTurn: isCurrentTurn,
                        angle: 0,
                        isHorizontal: true,
                        geometry: geometry,
                        game: game,
                        viewState: viewState
                    )
                }
            } else {
                // iPhone portrait: use VStack for top-to-bottom layout
                VStack(spacing: 4) {
                    GameBoardMeldRowView(
                        player: player, 
                        isHuman: isHumanPlayer, 
                        geometry: geometry,
                        game: game,
                        viewState: viewState
                    )
                    GamePlayerHandView(
                        player: player,
                        isHuman: isHumanPlayer,
                        isCurrentTurn: isCurrentTurn,
                        angle: 0,
                        isHorizontal: true,
                        geometry: geometry,
                        game: game,
                        viewState: viewState
                    )
                }
            }
        case .left:
            // Left player: melds right of held cards (towards trick area)
            if isLandscape {
                // iPad landscape: use HStack for left-to-right layout
                HStack(spacing: 6) {
                    GamePlayerHandView(
                        player: player,
                        isHuman: isHumanPlayer,
                        isCurrentTurn: isCurrentTurn,
                        angle: 0,
                        isHorizontal: true,
                        geometry: geometry,
                        game: game,
                        viewState: viewState
                    )
                    GameBoardMeldRowView(
                        player: player, 
                        isHuman: isHumanPlayer, 
                        geometry: geometry,
                        game: game,
                        viewState: viewState
                    )
                }
            } else {
                // iPhone portrait: use VStack for top-to-bottom layout
                VStack(spacing: 4) {
                    GamePlayerHandView(
                        player: player,
                        isHuman: isHumanPlayer,
                        isCurrentTurn: isCurrentTurn,
                        angle: 0,
                        isHorizontal: true,
                        geometry: geometry,
                        game: game,
                        viewState: viewState
                    )
                    GameBoardMeldRowView(
                        player: player, 
                        isHuman: isHumanPlayer, 
                        geometry: geometry,
                        game: game,
                        viewState: viewState
                    )
                }
            }
        }
    }

    private func rotation(for position: TablePosition) -> Angle {
        switch position {
        case .bottom: return .degrees(0)
        case .right: return .degrees(90)
        case .top: return .degrees(180)
        case .left: return .degrees(-90)
        }
    }

    private func nameOffset(for position: TablePosition) -> CGSize {
        let hasMelds = !player.meldsDeclared.isEmpty
        let isHuman = isHumanPlayer
        let isLandscape = geometry.size.width > geometry.size.height
        
        // Base spacing adjusted for device orientation
        let baseSpacing: CGFloat = if isHuman {
            isLandscape ? 140 : 120  // iPad landscape needs more space
        } else {
            isLandscape ? 100 : 80   // AI cards smaller but need visibility
        }
        
        let meldSpacing: CGFloat = if isHuman {
            isLandscape ? 140 : 120  // Extra space for human melds - was 190 : 170
        } else {
            isLandscape ? 150 : 130  // Extra space for AI melds
        }
        
        switch position {
        case .bottom: 
            return hasMelds ? CGSize(width: 0, height: -meldSpacing) : CGSize(width: 0, height: -baseSpacing)
        case .top: 
            return hasMelds ? CGSize(width: 0, height: meldSpacing) : CGSize(width: 0, height: baseSpacing)
        case .right: 
            return hasMelds ? CGSize(width: -meldSpacing, height: 0) : CGSize(width: -baseSpacing, height: 0)
        case .left: 
            return hasMelds ? CGSize(width: meldSpacing, height: 0) : CGSize(width: baseSpacing, height: 0)
        }
    }
}


