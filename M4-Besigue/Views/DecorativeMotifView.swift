import SwiftUI

struct DecorativeMotifView: View {
    var size: CGSize
    var body: some View {
        Circle()
            .strokeBorder(Color.white.opacity(0.2), lineWidth: 8)
            .frame(width: min(size.width, size.height) * 0.5, height: min(size.width, size.height) * 0.5)
            .position(x: size.width / 2, y: size.height / 2)
    }
} 