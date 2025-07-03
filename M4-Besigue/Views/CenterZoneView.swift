import SwiftUI

struct CenterZoneView: View {
    var deviceType: GameRootView.DeviceType
    var size: CGSize
    var isDrawAllowed: Bool
    var onDrawCard: () -> Void
    var body: some View {
        VStack {
            if isDrawAllowed {
                Button(action: onDrawCard) {
                    Text("Draw Card")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
} 