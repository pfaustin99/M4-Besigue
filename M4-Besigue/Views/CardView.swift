import SwiftUI

struct CardView: View {
    let card: PlayerCard
    let isSelected: Bool
    let isPlayable: Bool
    let showHint: Bool
    let onTap: () -> Void
    
    init(card: PlayerCard, isSelected: Bool = false, isPlayable: Bool = true, showHint: Bool = false, onTap: @escaping () -> Void) {
        self.card = card
        self.isSelected = isSelected
        self.isPlayable = isPlayable
        self.showHint = showHint
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Image(card.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 120)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : (showHint ? Color.yellow : Color.clear), lineWidth: isSelected ? 3 : (showHint ? 4 : 0))
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .shadow(color: isSelected ? .blue.opacity(0.5) : .clear, radius: isSelected ? 8 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
        .disabled(!isPlayable)
        .opacity(isPlayable ? 1.0 : 0.5)
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded {
                    if isPlayable { onTap() }
                }
        )
    }
}

struct CardBackView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image("card_back")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 120)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
    }
}

struct HandView: View {
    let cards: [PlayerCard]
    let playableCards: [PlayerCard]
    let selectedCards: [PlayerCard]
    let showHintFor: Set<UUID>
    let onCardTap: (PlayerCard) -> Void
    let onDoubleTap: (PlayerCard) -> Void
    
    init(cards: [PlayerCard], playableCards: [PlayerCard], selectedCards: [PlayerCard], showHintFor: Set<UUID> = [], onCardTap: @escaping (PlayerCard) -> Void, onDoubleTap: @escaping (PlayerCard) -> Void) {
        self.cards = cards
        self.playableCards = playableCards
        self.selectedCards = selectedCards
        self.showHintFor = showHintFor
        self.onCardTap = onCardTap
        self.onDoubleTap = onDoubleTap
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(cards) { card in
                    let isPlayable = playableCards.contains(card)
                    let isSelected = selectedCards.contains(card)
                    let showHint = showHintFor.contains(card.id)
                    CardView(
                        card: card,
                        isSelected: isSelected,
                        isPlayable: isPlayable,
                        showHint: showHint
                    ) {
                        onCardTap(card)
                    }
                    .onTapGesture(count: 2) {
                        onDoubleTap(card)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CardView(
            card: PlayerCard(card: Card(suit: .hearts, value: .ace)),
            isSelected: true
        ) {
            print("Card tapped")
        }
        
        HandView(
            cards: [
                PlayerCard(card: Card(suit: .hearts, value: .ace)),
                PlayerCard(card: Card(suit: .diamonds, value: .king)),
                PlayerCard(card: Card(suit: .clubs, value: .queen))
            ],
            playableCards: [
                PlayerCard(card: Card(suit: .hearts, value: .ace)),
                PlayerCard(card: Card(suit: .diamonds, value: .king))
            ],
            selectedCards: [],
            showHintFor: [],
            onCardTap: { card in
                print("Card tapped: \(card.displayName)")
            },
            onDoubleTap: { card in
                print("Card double tapped: \(card.displayName)")
            }
        )
    }
    .padding()
} 