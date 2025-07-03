// DEPRECATED: Use HandView for all player hands in the main UI.
import SwiftUI

struct HandZoneView: View {
    var cards: [PlayerCard]
    var isActive: Bool
    var selectedCard: PlayerCard? = nil
    var onCardSelected: ((PlayerCard) -> Void)? = nil
    var onCardPlayed: ((PlayerCard) -> Void)? = nil
    var body: some View {
        HStack(spacing: 8) {
            ForEach(cards) { card in
                CardView(
                    card: card,
                    isSelected: selectedCard?.id == card.id,
                    isPlayable: isActive,
                    showHint: false,
                    onTap: {
                        if isActive {
                            onCardSelected?(card)
                        }
                    }
                )
                .onTapGesture(count: 2) {
                    if isActive {
                        onCardPlayed?(card)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

#Preview {
    HandZoneView(cards: Array(repeating: PlayerCard.example, count: 7), isActive: true, selectedCard: nil, onCardSelected: nil, onCardPlayed: nil)
} 