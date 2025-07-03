import SwiftUI

struct PlayerZoneView: View {
    var player: Player
    var position: Alignment
    var isActive: Bool
    var deviceType: GameRootView.DeviceType
    var selectedCard: PlayerCard?
    var onCardSelected: ((PlayerCard) -> Void)?
    var onCardPlayed: ((PlayerCard) -> Void)?
    var body: some View {
        VStack {
            Text(player.name)
                .font(.headline)
                .padding(4)
            HandZoneView(
                cards: player.hand,
                isActive: isActive,
                selectedCard: selectedCard,
                onCardSelected: onCardSelected,
                onCardPlayed: onCardPlayed
            )
        }
        .frame(maxWidth: .infinity, alignment: position)
    }
} 