import SwiftUI

/// GameScoreboardView2 - Clean scoreboard component
struct GameScoreboardView2: View {
    let game: Game
    let settings: GameSettings
    
    var body: some View {
        VStack(spacing: 8) {
            Text("BÉSIGUE - \(game.players.count) Players")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
                .shadow(color: .yellow, radius: 1, x: 0.5, y: 0.5)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: game.players.count), spacing: 8) {
                ForEach(0..<game.players.count, id: \.self) { index in
                    PlayerScoreCardView(
                        player: game.players[index],
                        isCurrentPlayer: index == game.currentPlayerIndex
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

/// PlayerScoreCardView - Individual player score card
struct PlayerScoreCardView: View {
    let player: Player
    let isCurrentPlayer: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(player.name)
                .font(.caption)
                .fontWeight(.medium)
                .shadow(color: .yellow, radius: 1, x: 0.5, y: 0.5)
            
            HStack(spacing: 8) {
                Text("Score: \(player.score)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.3))
                    .cornerRadius(4)
                
                Text("Tricks: \(player.tricksWon)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.3))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(isCurrentPlayer ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
} 