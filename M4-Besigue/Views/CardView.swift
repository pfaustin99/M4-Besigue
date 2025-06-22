import SwiftUI

struct CardView: View {
    let card: Card
    let isSelected: Bool
    let isPlayable: Bool
    let onTap: () -> Void
    
    init(card: Card, isSelected: Bool = false, isPlayable: Bool = true, onTap: @escaping () -> Void) {
        self.card = card
        self.isSelected = isSelected
        self.isPlayable = isPlayable
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
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
        .disabled(!isPlayable)
        .opacity(isPlayable ? 1.0 : 0.5)
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
    let cards: [Card]
    let playableCards: [Card]
    let selectedCards: [Card]
    let onCardTap: (Card) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(cards) { card in
                    let isPlayable = playableCards.contains(card)
                    let isSelected = selectedCards.contains(card)
                    
                    CardView(
                        card: card,
                        isSelected: isSelected,
                        isPlayable: isPlayable
                    ) {
                        onCardTap(card)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct TrickView: View {
    let cards: [Card]
    let playerNames: [String]
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Current Trick")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if cards.isEmpty {
                Text("No cards played yet")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                HStack(spacing: 12) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                        VStack(spacing: 4) {
                            CardView(
                                card: card,
                                isSelected: false,
                                isPlayable: false
                            ) {
                                // No action for played cards
                            }
                            
                            if index < playerNames.count {
                                Text(playerNames[index])
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        CardView(
            card: Card(suit: .hearts, value: .ace),
            isSelected: true
        ) {
            print("Card tapped")
        }
        
        HandView(
            cards: [
                Card(suit: .hearts, value: .ace),
                Card(suit: .diamonds, value: .king),
                Card(suit: .clubs, value: .queen)
            ],
            playableCards: [
                Card(suit: .hearts, value: .ace),
                Card(suit: .diamonds, value: .king)
            ],
            selectedCards: []
        ) { card in
            print("Card tapped: \(card.displayName)")
        }
        
        TrickView(
            cards: [
                Card(suit: .hearts, value: .ace),
                Card(suit: .diamonds, value: .king)
            ],
            playerNames: ["You", "AI Player 1"]
        )
    }
    .padding()
} 