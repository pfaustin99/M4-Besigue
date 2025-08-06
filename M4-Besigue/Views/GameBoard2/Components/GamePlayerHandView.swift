import SwiftUI

/// GamePlayerHandView - Displays a player's hand (human or AI)
struct GamePlayerHandView: View {
    let player: Player
    let isHuman: Bool
    let isCurrentTurn: Bool
    let angle: Double
    let isHorizontal: Bool
    let geometry: GeometryProxy
    
    // MARK: - Responsive Card Sizing
    private var humanCardSize: CGSize {
        geometry.size.width < 768 ? CGSize(width: 50, height: 75) : CGSize(width: 100, height: 150)
    }
    
    private var aiCardSize: CGSize {
        geometry.size.width < 768 ? CGSize(width: 30, height: 45) : CGSize(width: 50, height: 75)
    }
    
    // MARK: - Responsive Stacking
    private var humanCardSpacing: CGFloat {
        geometry.size.width < 768 ? -30 : -25  // More overlap on iPhone
    }
    
    private var aiCardSpacing: CGFloat {
        geometry.size.width < 768 ? -35 : -25  // More overlap on iPhone
    }
    
    // MARK: - Responsive Container Frames
    private var humanContainerSize: CGSize {
        let cardWidth = humanCardSize.width
        let cardHeight = humanCardSize.height
        let spacing = humanCardSpacing
        let cardCount = CGFloat(player.held.count)
        
        if isHorizontal {
            let totalWidth = cardWidth + (spacing * (cardCount - 1))
            return CGSize(width: totalWidth, height: cardHeight)
        } else {
            let totalHeight = cardHeight + (spacing * (cardCount - 1))
            return CGSize(width: cardWidth, height: totalHeight)
        }
    }
    
    private var aiContainerSize: CGSize {
        let cardWidth = aiCardSize.width
        let cardHeight = aiCardSize.height
        let spacing = aiCardSpacing
        let cardCount = CGFloat(player.held.count)
        
        if isHorizontal {
            let totalWidth = cardWidth + (spacing * (cardCount - 1))
            return CGSize(width: totalWidth, height: cardHeight)
        } else {
            let totalHeight = cardHeight + (spacing * (cardCount - 1))
            return CGSize(width: cardWidth, height: totalHeight)
        }
    }
    
    var body: some View {
        Group {
            if isHuman && isCurrentTurn {
                // Human player's hand - show actual cards
                humanPlayerHandView
            } else {
                // AI player or non-current human - show card backs
                aiPlayerHandView
            }
        }
    }
    
    // MARK: - Human Player Hand View
    
    private var humanPlayerHandView: some View {
        HStack(spacing: humanCardSpacing) {
            ForEach(player.held) { card in
                CardView(
                    card: card,
                    isSelected: false, // Will be managed by parent
                    isPlayable: true,
                    showHint: false,
                    size: humanCardSize
                ) {
                    // Card selection will be handled by parent
                }
            }
        }
        .frame(width: humanContainerSize.width, height: humanContainerSize.height)
    }
    
    // MARK: - AI Player Hand View
    
    private var aiPlayerHandView: some View {
        HStack(spacing: aiCardSpacing) {
            ForEach(player.held) { _ in
                Image("card_back")
                    .resizable()
                    .frame(width: aiCardSize.width, height: aiCardSize.height)
            }
        }
        .frame(width: aiContainerSize.width, height: aiContainerSize.height)
    }
}

// MARK: - Preview
#if DEBUG
struct GamePlayerHandView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                // Human player hand
                GamePlayerHandView(
                    player: Player(name: "Human", type: .human),
                    isHuman: true,
                    isCurrentTurn: true,
                    angle: 0,
                    isHorizontal: true,
                    geometry: geometry
                )
                
                // AI player hand
                GamePlayerHandView(
                    player: Player(name: "AI", type: .ai),
                    isHuman: false,
                    isCurrentTurn: false,
                    angle: 0,
                    isHorizontal: true,
                    geometry: geometry
                )
            }
            .padding()
            .background(Color.green)
        }
    }
}
#endif 