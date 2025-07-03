import SwiftUI

struct HandZoneView: View {
    var cards: [PlayerCard]
    var isActive: Bool
    var selectedCard: PlayerCard? = nil
    var onCardSelected: ((PlayerCard) -> Void)? = nil
    var onCardPlayed: ((PlayerCard) -> Void)? = nil
    var body: some View {
        HStack(spacing: -24) {
            ForEach(cards) { card in
                Rectangle()
                    .fill(isActive ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 48, height: 72)
                    .cornerRadius(8)
                    .shadow(radius: isActive ? 6 : 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedCard?.id == card.id ? Color.yellow : Color.clear, lineWidth: 4)
                    )
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("handCard_\(card.id)")
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                if isActive {
                                    onCardPlayed?(card)
                                }
                            }
                            .exclusively(before:
                                TapGesture(count: 1)
                                    .onEnded {
                                        if isActive {
                                            onCardSelected?(card)
                                        }
                                    }
                            )
                    )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

#Preview {
    HandZoneView(cards: Array(repeating: PlayerCard.example, count: 7), isActive: true, selectedCard: nil, onCardSelected: nil, onCardPlayed: nil)
} 