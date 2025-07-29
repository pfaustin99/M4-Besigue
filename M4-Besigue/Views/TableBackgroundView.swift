import SwiftUI

struct TableBackgroundView: View {
    var color: Color = Color(red: 0.1, green: 0.4, blue: 0.2) // Dark green felt
    
    var body: some View {
        ZStack {
            // Base felt color
            Rectangle()
                .fill(color)
                .edgesIgnoringSafeArea(.all)
            
            // Subtle felt texture pattern
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                
                // Create subtle felt texture with small dots
                for i in stride(from: 0, to: size.width, by: 8) {
                    for j in stride(from: 0, to: size.height, by: 8) {
                        let dotRect = CGRect(x: i, y: j, width: 1, height: 1)
                        context.fill(Path(dotRect), with: .color(.black.opacity(0.1)))
                    }
                }
                
                // Add subtle border pattern
                let borderWidth: CGFloat = 20
                let borderRect = rect.insetBy(dx: borderWidth, dy: borderWidth)
                context.stroke(Path(borderRect), with: .color(.white.opacity(0.1)), lineWidth: 2)
                
                // Add corner decorations
                let cornerSize: CGFloat = 40
                let cornerRadius: CGFloat = 8
                
                // Top-left corner
                let topLeftRect = CGRect(x: borderWidth, y: borderWidth, width: cornerSize, height: cornerSize)
                context.fill(Path(roundedRect: topLeftRect, cornerRadius: cornerRadius), with: .color(.white.opacity(0.05)))
                
                // Top-right corner
                let topRightRect = CGRect(x: size.width - borderWidth - cornerSize, y: borderWidth, width: cornerSize, height: cornerSize)
                context.fill(Path(roundedRect: topRightRect, cornerRadius: cornerRadius), with: .color(.white.opacity(0.05)))
                
                // Bottom-left corner
                let bottomLeftRect = CGRect(x: borderWidth, y: size.height - borderWidth - cornerSize, width: cornerSize, height: cornerSize)
                context.fill(Path(roundedRect: bottomLeftRect, cornerRadius: cornerRadius), with: .color(.white.opacity(0.05)))
                
                // Bottom-right corner
                let bottomRightRect = CGRect(x: size.width - borderWidth - cornerSize, y: size.height - borderWidth - cornerSize, width: cornerSize, height: cornerSize)
                context.fill(Path(roundedRect: bottomRightRect, cornerRadius: cornerRadius), with: .color(.white.opacity(0.05)))
            }
        }
    }
} 