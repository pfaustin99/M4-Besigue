import SwiftUI

/// GameBoardMeldRowView - Displays a player's melds in a horizontal row
struct GameBoardMeldRowView: View {
    let player: Player
    let isHuman: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        if !player.meldsDeclared.isEmpty {
            HStack(spacing: 2) {  // Tighter spacing for overlay effect
                ForEach(player.meldsDeclared, id: \.id) { meld in
                    GameBoardMeldView(meld: meld, player: player, isHuman: isHuman, geometry: geometry)
                        .offset(y: -2)  // Slight upward offset for overlay effect
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
}

/// GameBoardMeldView - Individual meld display
private struct GameBoardMeldView: View {
    let meld: Meld
    let player: Player
    let isHuman: Bool
    let geometry: GeometryProxy
    
    private var meldCardSize: CGSize {
        let isLandscape = geometry.size.width > geometry.size.height
        let isIPad = geometry.size.width >= 768
        
        if isIPad {
            // iPad: larger meld cards for better visibility
            return isLandscape ? CGSize(width: 45, height: 67) : CGSize(width: 50, height: 75)
        } else {
            // iPhone: appropriately sized meld cards
            return isLandscape ? CGSize(width: 35, height: 52) : CGSize(width: 40, height: 60)
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Meld cards with better visibility
            HStack(spacing: -3) {  // Reduced overlap for better card visibility
                ForEach(meld.cardIDs, id: \.self) { cardId in
                    if let card = findCard(with: cardId) {
                        CardView(
                            card: card,
                            isSelected: false,
                            isPlayable: false,
                            showHint: false
                        ) { }
                        .frame(width: meldCardSize.width, height: meldCardSize.height)
                    }
                }
            }
            
            // Enhanced meld token
            HStack(spacing: 3) {
                Image(systemName: meldTypeIcon(for: meld.type))
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text("\(meld.pointValue)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.8))
                    )
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.9))
                    .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
            )
        }
    }
    
    private func meldTypeIcon(for type: MeldType) -> String {
        switch type {
        case .royalMarriage: return "crown.fill"
        case .commonMarriage: return "heart.fill"
        case .besigue: return "star.fill"
        case .fourJacks: return "j.circle.fill"
        case .fourQueens: return "q.circle.fill"
        case .fourKings: return "k.circle.fill"
        case .fourAces: return "a.circle.fill"
        case .fourJokers: return "joker.fill"
        case .sequence: return "list.number"
        }
    }
    
    private func findCard(with id: UUID) -> PlayerCard? {
        return player.cardByID(id)
    }
} 