import SwiftUI

/// GamePlayerNameView - Displays player name and status
struct GamePlayerNameView: View {
    let player: Player
    let position: CGPoint
    let isCurrentPlayer: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(player.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isCurrentPlayer ? .white : .secondary)
                
                if isCurrentPlayer {
                    Image(systemName: "person.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                }
                
                if player.type == .ai {
                    Image(systemName: "cpu")
                        .foregroundColor(.blue)
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isCurrentPlayer ? Color.blue.opacity(0.3) : Color.black.opacity(0.2))
            .cornerRadius(8)
        }
        .position(position)
    }
}

/// GamePlayerHandView - Displays player's hand
struct GamePlayerHandView: View {
    let player: Player
    let position: CGPoint
    let isHorizontal: Bool
    let angle: Double
    let game: Game
    let viewState: GameBoardViewState2
    
    var body: some View {
        Group {
            if player.isCurrentPlayer {
                // Current player: show face-up cards with full functionality
                HandView(
                    cards: player.held,
                    playableCards: game.getPlayableCards(),
                    selectedCards: viewState.selectedCards,
                    onCardTap: { card in handleCardTap(card) },
                    onDoubleTap: { card in handleCardDoubleTap(card) }
                )
                .frame(width: isHorizontal ? 600 : 160, height: isHorizontal ? 160 : 600)
            } else {
                // Other players: show card backs
                GameOtherPlayerHandView(
                    player: player,
                    isHorizontal: isHorizontal,
                    angle: angle
                )
            }
        }
        .position(position)
    }
    
    private func handleCardTap(_ card: PlayerCard) {
        if game.awaitingMeldChoice && game.currentPlayer.type == .human && game.canPlayerMeld && game.currentPlayer.id == game.trickWinnerId {
            if viewState.selectedCards.contains(card) {
                viewState.deselectCard(card)
            } else {
                viewState.selectCard(card)
            }
        }
    }
    
    private func handleCardDoubleTap(_ card: PlayerCard) {
        if game.currentPlayer.id == player.id && game.canPlayCard() {
            game.playCard(card, from: player)
            viewState.clearSelectedCards()
        }
    }
}

/// GameOtherPlayerHandView - Shows card backs for other players
struct GameOtherPlayerHandView: View {
    let player: Player
    let isHorizontal: Bool
    let angle: Double
    
    var body: some View {
        Group {
            if isHorizontal {
                HStack(spacing: -40) {
                    ForEach(Array(player.hand.enumerated()), id: \.element.id) { cardIndex, _ in
                        CardBackView { }
                            .frame(width: 60, height: 84)
                            .rotationEffect(.degrees(180 + getCardRotation(for: angle)))
                            .offset(x: CGFloat(cardIndex) * 8)
                    }
                }
            } else {
                VStack(spacing: -60) {
                    ForEach(Array(player.hand.enumerated()), id: \.element.id) { cardIndex, _ in
                        CardBackView { }
                            .frame(width: 60, height: 84)
                            .rotationEffect(.degrees(180 + getCardRotation(for: angle)))
                            .offset(y: CGFloat(cardIndex) * 8)
                    }
                }
            }
        }
    }
    
    private func getCardRotation(for angle: Double) -> Double {
        switch angle {
        case 90, 270: return 0    // Cards horizontal
        case 180, 0, 330, 210: return 90   // Cards vertical
        default: return 0
        }
    }
}

/// GamePlayerMeldView - Displays player's melded cards
struct GamePlayerMeldView: View {
    let player: Player
    let position: CGPoint
    let isHorizontal: Bool
    
    var body: some View {
        Group {
            if isHorizontal {
                HStack(spacing: 4) {
                    ForEach(0..<min(3, player.melded.count), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange)
                            .frame(width: 25, height: 35)
                    }
                }
            } else {
                VStack(spacing: 4) {
                    ForEach(0..<min(3, player.melded.count), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange)
                            .frame(width: 25, height: 35)
                    }
                }
            }
        }
        .position(position)
    }
} 