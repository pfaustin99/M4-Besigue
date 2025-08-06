
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
                .position(anchorPoint(for: position, in: geometry.size))
            }
        }
        .frame(width: max(0, geometry.size.width), height: max(0, geometry.size.height))
    }

    private func anchorPoint(for position: TablePosition, in size: CGSize) -> CGPoint {
        let safeWidth = max(0, size.width)
        let safeHeight = max(0, size.height)
        
        // Device detection: iPad is wider, iPhone is taller
        let isIPad = safeWidth > safeHeight
        
        if isIPad {
            // iPad (Landscape): Wide spread horizontally, compact vertically
            switch position {
            case .bottom:
                return CGPoint(x: safeWidth / 2, y: safeHeight * 0.85 - 50)
            case .top:
                return CGPoint(x: safeWidth / 2, y: safeHeight * 0.15 - 50)
            case .left:
                return CGPoint(x: safeWidth * 0.15, y: safeHeight / 2 - 50)
            case .right:
                return CGPoint(x: safeWidth * 0.85, y: safeHeight / 2 - 50)
            }
        } else {
            // iPhone (Portrait): Tall spread vertically, compact horizontally
            switch position {
            case .bottom:
                return CGPoint(x: safeWidth / 2, y: safeHeight * 0.9 - 50)
            case .top:
                return CGPoint(x: safeWidth / 2, y: safeHeight * 0.1 - 50)
            case .left:
                return CGPoint(x: safeWidth * 0.2, y: safeHeight / 2 - 50)
            case .right:
                return CGPoint(x: safeWidth * 0.8, y: safeHeight / 2 - 50)
            }
        }
    }
}
