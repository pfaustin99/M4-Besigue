
import SwiftUI

enum TablePosition {
    case bottom, right, top, left
}

struct PlayerTable: View {
    let player: Player
    let position: TablePosition
    let isCurrentTurn: Bool
    let isHumanPlayer: Bool
    let geometry: GeometryProxy
    let game: Game
    let viewState: GameBoardViewState2

    var body: some View {
        ZStack {
            // Main player content with proper meld positioning
            meldRowPosition(for: position)
                .rotationEffect(rotation(for: position))
            
            // Floating player name - always upright, positioned outside rotation
            SimplePlayerNameView(
                player: player,
                isCurrentTurn: isCurrentTurn,
                allPlayers: game.players
            )
            .offset(nameOffset(for: position))
        }
    }

    // MARK: - Layout-Aware Meld Positioning
    @ViewBuilder
    private func meldRowPosition(for position: TablePosition) -> some View {
        let isLandscape = geometry.size.width > geometry.size.height
        
        switch position {
        case .bottom:
            // Bottom player: melds above held cards (towards trick area)
            VStack(spacing: isLandscape ? 3 : 2) {  // 2-3px spacing between melds and held cards
                GameBoardMeldRowView(
                    player: player, 
                    isHuman: isHumanPlayer, 
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
                GamePlayerHandView(
                    player: player,
                    isHuman: isHumanPlayer,
                    isCurrentTurn: isCurrentTurn,
                    angle: 0,
                    isHorizontal: true,
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
            }
        case .top:
            // Top player: melds below held cards (towards trick area)
            VStack(spacing: isLandscape ? 3 : 2) {  // 2-3px spacing between held cards and melds
                GamePlayerHandView(
                    player: player,
                    isHuman: isHumanPlayer,
                    isCurrentTurn: isCurrentTurn,
                    angle: 0,
                    isHorizontal: true,
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
                GameBoardMeldRowView(
                    player: player, 
                    isHuman: isHumanPlayer, 
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
            }
        case .right:
            // Right player: melds left of held cards (towards trick area)
            HStack(spacing: isLandscape ? 3 : 2) {  // 2-3px spacing between melds and held cards
                GameBoardMeldRowView(
                    player: player, 
                    isHuman: isHumanPlayer, 
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
                GamePlayerHandView(
                    player: player,
                    isHuman: isHumanPlayer,
                    isCurrentTurn: isCurrentTurn,
                    angle: 90,
                    isHorizontal: false,
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
            }
        case .left:
            // Left player: melds right of held cards (towards trick area)
            HStack(spacing: isLandscape ? 3 : 2) {  // 2-3px spacing between held cards and melds
                GamePlayerHandView(
                    player: player,
                    isHuman: isHumanPlayer,
                    isCurrentTurn: isCurrentTurn,
                    angle: -90,
                    isHorizontal: false,
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
                GameBoardMeldRowView(
                    player: player, 
                    isHuman: isHumanPlayer, 
                    geometry: geometry,
                    game: game,
                    viewState: viewState
                )
            }
        }
    }

    private func rotation(for position: TablePosition) -> Angle {
        switch position {
        case .bottom: return .degrees(0)
        case .right: return .degrees(90)
        case .top: return .degrees(180)
        case .left: return .degrees(-90)
        }
    }

    private func nameOffset(for position: TablePosition) -> CGSize {
        let hasMelds = !player.meldsDeclared.isEmpty
        let isHuman = isHumanPlayer
        let isLandscape = geometry.size.width > geometry.size.height
        
        // Base spacing for positioning names over the cards
        let baseSpacing: CGFloat = if isHuman {
            isLandscape ? 20 : 15  // Reduced spacing to position over cards
        } else {
            isLandscape ? 15 : 10   // Reduced spacing for AI players
        }
        
        let meldSpacing: CGFloat = if isHuman {
            isLandscape ? 20 : 15  // Reduced spacing to position over cards
        } else {
            isLandscape ? 15 : 10   // Reduced spacing for AI players
        }
        
        switch position {
        case .bottom: 
            return hasMelds ? CGSize(width: 0, height: -meldSpacing) : CGSize(width: 0, height: -baseSpacing)
        case .top: 
            return hasMelds ? CGSize(width: 0, height: meldSpacing) : CGSize(width: 0, height: baseSpacing)
        case .right: 
            return hasMelds ? CGSize(width: -meldSpacing, height: 0) : CGSize(width: -baseSpacing, height: 0)
        case .left: 
            return hasMelds ? CGSize(width: meldSpacing, height: 0) : CGSize(width: baseSpacing, height: 0)
        }
    }
}

// MARK: - Simple Player Name View
/// SimplePlayerNameView - Simplified view for displaying "Player #" with turn highlighting
struct SimplePlayerNameView: View {
    @ObservedObject var player: Player
    let isCurrentTurn: Bool
    let allPlayers: [Player]
    
    // MARK: - Device Detection
    private var isIPad: Bool {
        UIScreen.main.bounds.width >= 768
    }
    
    // MARK: - Responsive Font Sizing
    private var playerNameFont: Font {
        isIPad ? .body : .callout
    }
    
    // MARK: - Active Turn Styling
    private var namePlateColor: Color {
        isCurrentTurn ? Color(hex: "00209F") : Color.white
    }
    
    private var namePlateBorderColor: Color {
        isCurrentTurn ? Color(hex: "F1B517") : Color(hex: "F1B517")
    }
    
    private var namePlateTextColor: Color {
        isCurrentTurn ? .white : .black
    }
    
    // Get player number (1-based index)
    private var playerNumber: Int {
        if let index = allPlayers.firstIndex(where: { $0.id == player.id }) {
            return index + 1
        }
        return 1
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Player name plate
            HStack(spacing: 4) {
                Text("Player \(playerNumber)")
                    .font(playerNameFont)
                    .fontWeight(.semibold)
                    .foregroundColor(namePlateTextColor)
                
                if isCurrentTurn {
                    Image(systemName: "person.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                }
                
                if player.type == .ai {
                    Image(systemName: "cpu")
                        .foregroundColor(.blue)
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(namePlateColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(namePlateBorderColor, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4) // Enhanced shadow for floating names
        }
    }
}


