import SwiftUI

/// GameBoardBackgroundView - Simple background component
struct GameBoardBackgroundView: View {
    var body: some View {
        Rectangle()
            .fill(GameBoardConstants.Colors.backgroundGreen)
            .edgesIgnoringSafeArea(.all)
    }
} 