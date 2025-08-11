import SwiftUI

struct GameRootView: View {
    enum DeviceType { case iPhone, iPad, desktop }
    enum InteractionMode { case tapToSelect, dragAndDrop }
    
    var deviceType: DeviceType
    var tableColor: Color
    var interactionMode: InteractionMode
    @ObservedObject var game: Game
    
    var body: some View {
        ZStack {
            tableColor
                .ignoresSafeArea()

            GameBoardView2(
                game: game, 
                settings: game.settings, 
                gameRules: game.gameRules,
                onEndGame: {}
            )
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 4) // Minimal top padding to keep header at top
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 10)
            )
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
