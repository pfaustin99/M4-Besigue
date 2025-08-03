import SwiftUI

// MARK: - GameBoardView Layout Calculations Extension
extension GameBoardView {
    
    // MARK: - Player Position Calculations
    /// Calculates player positions for the given player count and geometry
    /// - Parameters:
    ///   - index: The player index
    ///   - playerCount: Total number of players
    ///   - center: Center point of the game board
    ///   - geometry: Geometry proxy for size calculations
    /// - Returns: PlayerPosition struct with all position data
    func getPlayerPositions(index: Int, playerCount: Int, center: CGPoint, geometry: GeometryProxy) -> PlayerPosition {
        let minSide = min(geometry.size.width, geometry.size.height)
        let radiusFactors = [
            GameBoardConstants.RadiusFactors.avatar,
            GameBoardConstants.RadiusFactors.hand,
            GameBoardConstants.RadiusFactors.meld
        ]
        
        let angles = getPlayerAngles(for: playerCount)
        let playerOrder = getPlayerOrder(for: playerCount)
        let actualIndex = playerOrder[index]
        let angle = angles[actualIndex]
        
        let avatarPosition = positionOnAxis(radiusFactor: radiusFactors[0], angle: angle, center: center, minSide: minSide)
        let handPosition = positionOnAxis(radiusFactor: radiusFactors[1], angle: angle, center: center, minSide: minSide)
        let meldPosition = positionOnAxis(radiusFactor: radiusFactors[2], angle: angle, center: center, minSide: minSide)
        
        let isHorizontal = abs(angle - 90) < 45 || abs(angle - 270) < 45
        
        return PlayerPosition(
            avatarPosition: avatarPosition,
            handPosition: handPosition,
            meldPosition: meldPosition,
            isHorizontal: isHorizontal,
            angle: angle
        )
    }
    
    /// Calculates position on a circle based on radius factor and angle
    /// - Parameters:
    ///   - radiusFactor: Factor to multiply by the minimum side
    ///   - angle: Angle in degrees
    ///   - center: Center point
    ///   - minSide: Minimum side length
    /// - Returns: Calculated position
    private func positionOnAxis(radiusFactor: CGFloat, angle: Double, center: CGPoint, minSide: CGFloat) -> CGPoint {
        let radius = minSide * radiusFactor / 2
        let radians = angle * .pi / 180
        let x = center.x + radius * cos(radians)
        let y = center.y + radius * sin(radians)
        return CGPoint(x: x, y: y)
    }
    
    /// Gets the player angles for the given player count
    /// - Parameter playerCount: Number of players
    /// - Returns: Array of angles for each player
    private func getPlayerAngles(for playerCount: Int) -> [Double] {
        switch playerCount {
        case 2:
            return GameBoardConstants.PlayerAngles.twoPlayer
        case 3:
            return GameBoardConstants.PlayerAngles.threePlayer
        case 4:
            return GameBoardConstants.PlayerAngles.fourPlayer
        default:
            return GameBoardConstants.PlayerAngles.twoPlayer
        }
    }
    
    /// Gets the player order for the given player count
    /// - Parameter playerCount: Number of players
    /// - Returns: Array of player indices in display order
    private func getPlayerOrder(for playerCount: Int) -> [Int] {
        switch playerCount {
        case 2:
            return GameBoardConstants.PlayerOrder.twoPlayer
        case 3:
            return GameBoardConstants.PlayerOrder.threePlayer
        case 4:
            return GameBoardConstants.PlayerOrder.fourPlayer
        default:
            return GameBoardConstants.PlayerOrder.twoPlayer
        }
    }
    
    // MARK: - Card Rotation Calculations
    /// Calculates the rotation for cards based on player angle
    /// - Parameter angle: Player angle in degrees
    /// - Returns: Card rotation in degrees
    func getCardRotation(for angle: Double) -> Double {
        // Cards should face toward the player
        return angle - 90
    }
    
    // MARK: - Frame Calculations
    /// Calculates the frame for player hands based on orientation
    /// - Parameter isHorizontal: Whether the hand is horizontal
    /// - Returns: Frame dimensions
    func getHandFrame(isHorizontal: Bool) -> (width: CGFloat, height: CGFloat) {
        if isHorizontal {
            return (GameBoardConstants.horizontalHandWidth, GameBoardConstants.horizontalHandHeight)
        } else {
            return (GameBoardConstants.verticalHandWidth, GameBoardConstants.verticalHandHeight)
        }
    }
    
    /// Calculates the frame for the trick area
    /// - Returns: Frame dimensions for trick area
    func getTrickAreaFrame() -> (width: CGFloat, height: CGFloat) {
        return (GameBoardConstants.trickAreaWidth, GameBoardConstants.trickAreaHeight)
    }
    
    // MARK: - Stack Calculations
    /// Calculates the offset for card stacks
    /// - Parameter index: Card index in the stack
    /// - Returns: Offset for the card
    func getStackOffset(for index: Int) -> CGFloat {
        return CGFloat(index) * GameBoardConstants.stackOffset
    }
    
    /// Calculates the maximum number of visible cards
    /// - Returns: Maximum number of cards to show
    func getMaxVisibleCards() -> Int {
        return GameBoardConstants.maxVisibleCards
    }
    
    // MARK: - Center Calculations
    /// Calculates the center point of the game board
    /// - Parameter geometry: Geometry proxy
    /// - Returns: Center point
    func getGameBoardCenter(geometry: GeometryProxy) -> CGPoint {
        return CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
}

// MARK: - Player Position Data Structure
/// Data structure to hold all position information for a player
struct PlayerPosition {
    let avatarPosition: CGPoint
    let handPosition: CGPoint
    let meldPosition: CGPoint
    let isHorizontal: Bool
    let angle: Double
} 