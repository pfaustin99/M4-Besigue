import SwiftUI

/// Constants used throughout GameBoardView to replace magic numbers
struct GameBoardConstants {
    // MARK: - Card Dimensions
    static let cardWidth: CGFloat = 80
    static let cardHeight: CGFloat = 120
    static let smallCardWidth: CGFloat = 50
    static let smallCardHeight: CGFloat = 70
    static let meldCardWidth: CGFloat = 40
    static let meldCardHeight: CGFloat = 56
    static let badgeSize: CGFloat = 12
    
    // MARK: - Animation
    static let animationDuration: Double = 0.6
    static let cardSelectionAnimationDuration: Double = 0.2
    static let buttonAnimationDuration: Double = 0.1
    
    // MARK: - Layout
    static let maxVisibleCards = 16
    static let stackOffset: CGFloat = 2
    static let maxStackDepth: Int = 16
    static let cardSpacing: CGFloat = -20
    static let cardOverlap: CGFloat = 8
    static let meldCardSpacing: CGFloat = 4
    static let badgeSpacing: CGFloat = 1
    
    // MARK: - Padding and Spacing
    static let buttonPadding: CGFloat = 16
    static let topButtonPadding: CGFloat = 12
    static let scoreboardPadding: CGFloat = 8
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 2
    static let cornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 12
    static let extraLargeCornerRadius: CGFloat = 40
    
    // MARK: - Stroke and Border
    static let strokeWidth: CGFloat = 4
    static let thinStrokeWidth: CGFloat = 1
    static let mediumStrokeWidth: CGFloat = 2
    
    // MARK: - Shadow
    static let shadowRadius: CGFloat = 2
    static let cardShadowRadius: CGFloat = 8
    static let titleShadowRadius: CGFloat = 4
    
    // MARK: - Frame Dimensions
    static let horizontalHandWidth: CGFloat = 600
    static let horizontalHandHeight: CGFloat = 160
    static let verticalHandWidth: CGFloat = 160
    static let verticalHandHeight: CGFloat = 600
    static let trickAreaWidth: CGFloat = 200
    static let trickAreaHeight: CGFloat = 150
    static let buttonSpacing: CGFloat = 10
    static let scoreboardSpacing: CGFloat = 10
    
    // MARK: - Radius Factors for Player Positioning
    struct RadiusFactors {
        static let avatar: CGFloat = 0.85
        static let hand: CGFloat = 0.65
        static let meld: CGFloat = 0.45
    }
    
    // MARK: - Player Angles for Different Player Counts
    struct PlayerAngles {
        static let twoPlayer: [Double] = [90, 270]
        static let threePlayer: [Double] = [90, 210, 330]
        static let fourPlayer: [Double] = [90, 180, 270, 0]
    }
    
    // MARK: - Colors
    struct Colors {
        static let primaryGreen = Color(hex: "#016A16")
        static let primaryRed = Color(hex: "#D21034")
        static let primaryGold = Color(hex: "#F1B517")
        static let backgroundGreen = Color(hex: "#016A16").opacity(0.3)
        static let tableGreen = Color(hex: "#016A16").opacity(0.2)
        static let scoreBackground = Color.white.opacity(0.95)
        static let currentPlayerBackground = Color(hex: "#016A16").opacity(0.2)
        static let otherPlayerBackground = Color.gray.opacity(0.1)
        static let meldBackground = Color(hex: "#016A16").opacity(0.1)
        static let scoreBackgroundRed = Color(hex: "#D21034").opacity(0.8)
        static let scoreBackgroundGold = Color(hex: "#F1B517").opacity(0.8)
        static let selectedCardShadow = Color(hex: "#D21034").opacity(0.5)
        static let buttonBlue = Color.blue.opacity(0.2)
        static let buttonGray = Color.gray.opacity(0.2)
        static let buttonRed = Color.red.opacity(0.2)
        static let buttonGreen = Color.green.opacity(0.2)
        static let buttonOrange = Color.orange.opacity(0.2)
        static let buttonPurple = Color.purple.opacity(0.2)
        static let overlayBackground = Color.black.opacity(0.6)
        static let strokeGreen = Color.green.opacity(0.3)
        static let strokeBlue = Color.blue.opacity(0.3)
    }
    
    // MARK: - Font Sizes
    struct FontSizes {
        static let title: CGFloat = 26
        static let title2: CGFloat = 22
        static let caption: CGFloat = 12
        static let caption2: CGFloat = 10
        static let badge: CGFloat = 12
    }
    
    // MARK: - Player Order for Different Counts
    struct PlayerOrder {
        static let twoPlayer = [0, 2]      // bottom, top
        static let threePlayer = [0, 2, 1] // bottom, top, right
        static let fourPlayer = [0, 2, 1, 3] // bottom, top, right, left
    }
} 