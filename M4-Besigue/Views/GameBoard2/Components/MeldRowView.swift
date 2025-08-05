import SwiftUI

/// GameBoardMeldRowView - Displays a player's melds in a horizontal row
struct GameBoardMeldRowView: View {
    let player: Player
    let isHuman: Bool
    
    var body: some View {
        if !player.meldsDeclared.isEmpty {
            HStack(spacing: 8) {
                ForEach(player.meldsDeclared, id: \.id) { meld in
                    GameBoardMeldView(meld: meld, player: player, isHuman: isHuman)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.1))
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

/// GameBoardMeldView - Individual meld display
private struct GameBoardMeldView: View {
    let meld: Meld
    let player: Player
    let isHuman: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            // Meld cards
            HStack(spacing: 2) {
                ForEach(meld.cardIDs, id: \.self) { cardId in
                    if let card = findCard(with: cardId) {
                        CardView(
                            card: card,
                            isSelected: false,
                            isPlayable: false,
                            showHint: false
                        ) { }
                        .frame(width: 30, height: 45)
                    }
                }
            }
            
            // Meld type and points
            Text(meld.type.name)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("\(meld.pointValue)")
                .font(.caption2)
                .foregroundColor(.yellow)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.3))
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func findCard(with id: UUID) -> PlayerCard? {
        return player.cardByID(id)
    }
} 