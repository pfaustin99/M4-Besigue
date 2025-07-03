import SwiftUI

struct GameRootView: View {
    enum DeviceType { case iPhone, iPad, desktop }
    enum InteractionMode { case tapToSelect, dragAndDrop }
    
    var deviceType: DeviceType
    var tableColor: Color
    var interactionMode: InteractionMode
    @ObservedObject var game: Game
    
    var body: some View {
        GameBoardView(game: game, settings: game.settings)
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