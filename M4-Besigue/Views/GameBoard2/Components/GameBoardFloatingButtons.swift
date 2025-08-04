import SwiftUI

/// GameBoardFloatingButtons - Floating action buttons for game controls
struct GameBoardFloatingButtons: View {
    let game: Game
    let viewState: GameBoardViewState2
    
    var body: some View {
        VStack(spacing: 12) {
            // Settings button
            Button(action: {
                viewState.showSettings()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.8))
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