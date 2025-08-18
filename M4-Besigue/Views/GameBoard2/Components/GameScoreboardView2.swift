import SwiftUI

/// GameScoreboardView2 - Elegant scoreboard component with BÉSIGUE branding
struct GameScoreboardView2: View {
    let game: Game
    let settings: GameSettings
    
    var body: some View {
        VStack(spacing: 0) {
            // Elegant BÉSIGUE title with modern styling
            Text("BÉSIGUE")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "F1B517"), // Regal Gold
                            Color(hex: "D21034")  // Royal Crimson
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.8),
                                    Color.black.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "F1B517").opacity(0.6),
                                            Color(hex: "D21034").opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

// PlayerScoreCardView removed - scores now displayed next to player names 
