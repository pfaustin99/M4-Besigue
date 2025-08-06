import SwiftUI

/// GameBoardFloatingButtons - Floating action buttons for game controls
struct GameBoardFloatingButtons: View {
    let game: Game
    let viewState: GameBoardViewState2
    let onEndGame: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // End Game button
            Button(action: {
                onEndGame()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            
            // Badge Legend button
            Button(action: {
                viewState.showBadgeLegend()
            }) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.orange.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
        }
        .padding(.trailing, 16)
        .padding(.top, 16)
    }
} 