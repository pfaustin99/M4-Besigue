import SwiftUI

struct GameOverlayView: View {
    var body: some View {
        Color.black.opacity(0.2)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                Text("Game Overlay")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            )
    }
} 