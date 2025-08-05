import SwiftUI

/// GamePlayerHandView - Displays a player's hand (human or AI)
struct GamePlayerHandView: View {
    let player: Player
    let isHuman: Bool
    let isCurrentTurn: Bool
    let angle: Double
    let isHorizontal: Bool
    
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
        HStack(spacing: -15) {
            ForEach(player.held) { card in
                CardView(
                    card: card,
                    isSelected: false, // Will be managed by parent
                    isPlayable: true,
                    showHint: false
                ) {
                    // Card selection will be handled by parent
                }
                .frame(width: 70, height: 105)
            }
        }
        .frame(width: isHorizontal ? 550 : 105, height: isHorizontal ? 105 : 550)
    }
    
    // MARK: - AI Player Hand View
    
    private var aiPlayerHandView: some View {
        HStack(spacing: -20) {
            ForEach(player.held) { _ in
                Image("card_back")
                    .resizable()
                    .frame(width: 40, height: 60)
            }
        }
        .frame(width: isHorizontal ? 400 : 60, height: isHorizontal ? 60 : 400)
    }
}

// MARK: - Preview
#if DEBUG
struct GamePlayerHandView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Human player hand
            GamePlayerHandView(
                player: Player(name: "Human", type: .human),
                isHuman: true,
                isCurrentTurn: true,
                angle: 0,
                isHorizontal: true
            )
            
            // AI player hand
            GamePlayerHandView(
                player: Player(name: "AI", type: .ai),
                isHuman: false,
                isCurrentTurn: false,
                angle: 0,
                isHorizontal: true
            )
        }
        .padding()
        .background(Color.green)
    }
}
#endif 