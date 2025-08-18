
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
            // Main player content (melds and hand) - rotated
            VStack(spacing: 8) {
                GameBoardMeldRowView(player: player, isHuman: isHumanPlayer)
                GamePlayerHandView(
                    player: player,
                    isHuman: isHumanPlayer,
                    isCurrentTurn: isCurrentTurn, // This is now only used for visual highlighting, not visibility
                    angle: 0,
                    isHorizontal: true,
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
            }
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
        
        switch position {
        case .bottom: 
            return hasMelds ? CGSize(width: 0, height: -150) : CGSize(width: 0, height: -100)
        case .top: 
            return hasMelds ? CGSize(width: 0, height: 150) : CGSize(width: 0, height: 100)
        case .right: 
            return hasMelds ? CGSize(width: -150, height: 0) : CGSize(width: -100, height: 0)
        case .left: 
            return hasMelds ? CGSize(width: 150, height: 0) : CGSize(width: 100, height: 0)
        }
    }
}


