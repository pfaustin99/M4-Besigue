import SwiftUI

/// FloatingDrawPileView - A draggable draw pile with card count
struct FloatingDrawPileView: View {
    let game: Game
    @State private var position = CGPoint(x: 100, y: 100)
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 8) {
            // "Draw Pile" label above - made more prominent
            Text("Draw Pile")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#00209F"))
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .offset(y: -40) // Move label up by 15 points
            
            // Draw pile cards with centered count
            ZStack {
                // Card stack
                ForEach(0..<min(3, game.deck.cards.count), id: \.self) { index in
                    CardBackView { }
                        .frame(width: 25, height: 35)
                        .offset(x: CGFloat(index) * 1.5, y: CGFloat(index) * 1.5)
                }
                
                // Centered card count
                Text("\(game.deck.cards.count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#D21034"))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 60)
        .background(Color.yellow.opacity(0.2)) // Debug background to see the VStack bounds
        .position(position)
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    position = value.location
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}

// MARK: - Preview
#if DEBUG
struct FloatingDrawPileView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.green
            FloatingDrawPileView(game: Game(gameRules: GameRules()))
        }
    }
}
#endif 