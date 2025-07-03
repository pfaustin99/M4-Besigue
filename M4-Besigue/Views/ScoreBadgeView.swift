import SwiftUI

struct ScoreBadgeView: View {
    var score: Int
    var body: some View {
        Text("Score: \(score)")
            .padding(6)
            .background(Color.green.opacity(0.2))
            .cornerRadius(8)
    }
} 