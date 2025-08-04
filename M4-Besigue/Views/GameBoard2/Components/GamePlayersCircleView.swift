import SwiftUI

/// GamePlayersCircleView - Arranges players in a circle around the game table
struct GamePlayersCircleView: View {
    let game: Game
    let settings: GameSettings
    let viewState: GameBoardViewState2
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            ForEach(0..<game.players.count, id: \.self) { index in
                GamePlayerView(
                    player: game.players[index],
                    index: index,
                    playerCount: game.players.count,
                    game: game,
                    settings: settings,
                    viewState: viewState,
                    geometry: geometry
                )
            }
        }
    }
}

/// GamePlayerView - Individual player view positioned around the table
struct GamePlayerView: View {
    let player: Player
    let index: Int
    let playerCount: Int
    let game: Game
    let settings: GameSettings
    let viewState: GameBoardViewState2
    let geometry: GeometryProxy
    
    private var position: GamePlayerPosition {
        getPlayerPosition(
            index: index,
            playerCount: playerCount,
            geometry: geometry
        )
    }
    
    var body: some View {
        ZStack {
            // Player name
            GamePlayerNameView(
                player: player,
                position: position.avatarPosition,
                isCurrentPlayer: player.isCurrentPlayer
            )
            
            // Player hand
            GamePlayerHandView(
                player: player,
                position: position.handPosition,
                isHorizontal: position.isHorizontal,
                angle: position.angle,
                game: game,
                viewState: viewState
            )
            
            // Player melds (if any)
            if !player.melded.isEmpty {
                GamePlayerMeldView(
                    player: player,
                    position: position.meldPosition,
                    isHorizontal: position.isHorizontal
                )
            }
        }
    }
    
    private func getPlayerPosition(
        index: Int,
        playerCount: Int,
        geometry: GeometryProxy
    ) -> GamePlayerPosition {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let minSide = min(geometry.size.width, geometry.size.height)
        
        let radiusFactors = (avatar: 0.85, hand: 0.65, meld: 0.45)
        let angles: [Double] = {
            switch playerCount {
            case 2: return [90, 270]
            case 3: return [90, 210, 330]
            case 4: return [90, 180, 270, 0]
            default: return []
            }
        }()
        
        let angle = angles[index]
        let rad = Angle(degrees: angle).radians
        let isHorizontal = angle == 90 || angle == 270
        
        let avatarPoint = {
            let radius = minSide * radiusFactors.avatar / 2
            let x = center.x + CGFloat(cos(rad)) * radius
            let y = center.y + CGFloat(sin(rad)) * radius
            return CGPoint(x: x, y: y)
        }()
        
        let handPoint = {
            let radius = minSide * radiusFactors.hand / 2
            let x = center.x + CGFloat(cos(rad)) * radius
            let y = center.y + CGFloat(sin(rad)) * radius
            return CGPoint(x: x, y: y)
        }()
        
        let meldPoint = {
            let radius = minSide * radiusFactors.meld / 2
            let x = center.x + CGFloat(cos(rad)) * radius
            let y = center.y + CGFloat(sin(rad)) * radius
            return CGPoint(x: x, y: y)
        }()
        
        return GamePlayerPosition(
            avatarPosition: avatarPoint,
            handPosition: handPoint,
            meldPosition: meldPoint,
            isHorizontal: isHorizontal,
            angle: angle
        )
    }
}

/// GamePlayerPosition - Position data for a player in GameBoard2
struct GamePlayerPosition {
    let avatarPosition: CGPoint
    let handPosition: CGPoint
    let meldPosition: CGPoint
    let isHorizontal: Bool
    let angle: Double
} 