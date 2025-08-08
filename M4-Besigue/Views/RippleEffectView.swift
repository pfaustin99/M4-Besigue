import SwiftUI

struct RippleEffectView: View {
    var origin: CGPoint
    var maxRadius: CGFloat
    var color: Color = Color(hex: "F1B517")
    
    @State private var animate = false
    @State private var shouldRemove = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(color.opacity(Double(1.0 - (Double(i) * 0.3))), lineWidth: 3)
                    .frame(width: animate ? maxRadius : 0, height: animate ? maxRadius : 0)
                    .position(origin)
                    .scaleEffect(animate ? 1.0 + CGFloat(i) * 0.3 : 0.0)
                    .opacity(animate ? 0.0 : 1.0)
                    .animation(
                        Animation.easeOut(duration: 2.0)
                            .delay(Double(i) * 0.2),
                        value: animate
                    )
            }
            // Optional glowing blur ring
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: animate ? maxRadius * 0.6 : 0, height: animate ? maxRadius * 0.6 : 0)
                .position(origin)
                .blur(radius: 20)
                .animation(.easeOut(duration: 2.0), value: animate)
        }
        .opacity(shouldRemove ? 0 : 1)
        .onAppear {
            animate = true
            
            // Remove the view after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    shouldRemove = true
                }
            }
        }
    }
} 