
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
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
                .position(anchorPoint(for: position, in: geometry.size))
            }
        }
        .frame(width: max(0, geometry.size.width), height: max(0, geometry.size.height))
        .clipped() // Ensure content doesn't overflow the frame
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
                // Position bottom player at the bottom of their allocated space
                return CGPoint(x: safeWidth / 2, y: safeHeight * 0.8)
            case .top:
                // Position top player at the top of their allocated space
                return CGPoint(x: safeWidth / 2, y: safeHeight * 0.2)
            case .left:
                return CGPoint(x: safeWidth * 0.15, y: safeHeight / 2)
            case .right:
                return CGPoint(x: safeWidth * 0.85, y: safeHeight / 2)
            }
        } else {
            // iPhone (Portrait): Tall spread vertically, compact horizontally
            switch position {
            case .bottom:
                // Position bottom player at the bottom of their allocated space
                return CGPoint(x: safeWidth / 2, y: safeHeight * 0.85)
            case .top:
                // Position top player at the top of their allocated space
                return CGPoint(x: safeWidth / 2, y: safeHeight * 0.15)
            case .left:
                return CGPoint(x: safeWidth * 0.2, y: safeHeight / 2)
            case .right:
                return CGPoint(x: safeWidth * 0.8, y: safeHeight / 2)
            }
        }
    }
}
