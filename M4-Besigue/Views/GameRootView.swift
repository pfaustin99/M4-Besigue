import SwiftUI

struct GameRootView: View {
    enum DeviceType { case iPhone, iPad, desktop }
    enum InteractionMode { case tapToSelect, dragAndDrop }
    
    var deviceType: DeviceType
    var tableColor: Color
    var interactionMode: InteractionMode
    @ObservedObject var game: Game
    @State private var selectedCard: PlayerCard? = nil
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                TableBackgroundView(color: tableColor)
                DecorativeMotifView(size: geo.size)
                CenterZoneView(
                    deviceType: deviceType, 
                    size: geo.size,
                    isDrawAllowed: game.isDrawCycle,
                    onDrawCard: {
                        game.drawCardForCurrentDrawTurn()
                    }
                )
                ForEach(Array(game.players.enumerated()), id: \.element.id) { idx, player in
                    let active = idx == game.currentPlayerIndex
                    PlayerZoneView(
                        player: player,
                        position: playerZonePosition(idx: idx, count: game.players.count, geo: geo),
                        isActive: active,
                        deviceType: deviceType,
                        selectedCard: active ? selectedCard : nil,
                        onCardSelected: active ? { card in
                            selectedCard = card
                        } : nil,
                        onCardPlayed: active ? { card in
                            if selectedCard?.id == card.id {
                                game.playCard(card, from: player)
                                selectedCard = nil
                            }
                        } : nil
                    )
                }
            }
            .padding(.horizontal, geo.size.width * 0.06)
            .padding(.vertical, geo.size.height * 0.06)
        }
        .onAppear {
            game.startNewGame()
            if game.currentPlayer.type == .ai {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    game.processAITurn()
                }
            }
        }
    }
    
    func playerZonePosition(idx: Int, count: Int, geo: GeometryProxy) -> Alignment {
        switch count {
        case 2:
            return idx == 0 ? .bottom : .top
        case 4:
            return [ .bottom, .top, .leading, .trailing ][idx]
        default:
            return .center
        }
    }
}

#Preview {
    GameRootView(
        deviceType: .iPad,
        tableColor: Color("CaribbeanBlue"),
        interactionMode: .tapToSelect,
        game: Game(gameRules: GameRules())
    )
} 