
import SwiftUI

struct GamePlayersLayoutView: View {
    let game: Game
    let settings: GameSettings
    let viewState: GameBoardViewState2
    let geometry: GeometryProxy

    private var tablePositions: [TablePosition] {
        switch game.players.count {
        case 2: return [.bottom, .top]
        case 3: return [.bottom, .top, .right]
        case 4: return [.bottom, .right, .top, .left]
        default: return []
        }
    }

    var body: some View {
        ZStack {
            ForEach(Array(zip(game.players.indices, tablePositions)), id: \.0) { (index, position) in
                let player = game.players[index]
                PlayerTable(
                    player: player,
                    position: position,
                    isCurrentTurn: index == game.currentPlayerIndex,
                    isHumanPlayer: index == 0,
                    geometry: geometry
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .position(anchorPoint(for: position, in: geometry.size))
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .border(Color.red, width: 2) // DEBUG: Show players layout bounds
    }

    private func anchorPoint(for position: TablePosition, in size: CGSize) -> CGPoint {
        switch position {
        case .bottom:
            return CGPoint(x: size.width / 2, y: size.height * 0.75 - 50)
        case .top:
            return CGPoint(x: size.width / 2, y: size.height * 0.25 - 50)
        case .left:
            return CGPoint(x: size.width * 0.25, y: size.height / 2 - 50)
        case .right:
            return CGPoint(x: size.width * 0.75, y: size.height / 2 - 50)
        }
    }
}
