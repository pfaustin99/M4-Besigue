import SwiftUI

/// GameBoardCenterSection - Center section containing the main game area
struct GameBoardCenterSection: View {
    @ObservedObject var game: Game
    let settings: GameSettings
    let gameRules: GameRules
    
    var body: some View {
        VStack {
            // Main trick area content
            if game.isShowingCompletedTrick {
                CompletedTrickView(
                    cards: game.completedTrick,
                    game: game,
                    settings: settings,
                    gameRules: gameRules
                )
                .frame(width: 200, height: 120)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: game.completedTrick.count)
            } else if !game.currentTrick.isEmpty {
                CompletedTrickView(
                    cards: game.currentTrick,
                    game: game,
                    settings: settings,
                    gameRules: gameRules
                )
                .frame(width: 200, height: 120)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: game.currentTrick.count)
            } else {
                // Empty state - minimal and clean
                Color.clear
                    .frame(width: 200, height: 120)
            }
            
            Spacer()
        }
        .padding(3) // Reduced from default padding to 3 points
        .onAppear {
            print("🎯 GameBoardCenterSection appeared")
            print("   currentTrick count: \(game.currentTrick.count)")
            print("   currentTrick isEmpty: \(game.currentTrick.isEmpty)")
            print("   isShowingCompletedTrick: \(game.isShowingCompletedTrick)")
        }
        .onChange(of: game.currentTrick.count) { _, newCount in
            print("🎯 GameBoardCenterSection - currentTrick count changed to: \(newCount)")
            print("   Will show: \(game.isShowingCompletedTrick ? "CompletedTrick" : (!game.currentTrick.isEmpty ? "CurrentTrick" : "Empty"))")
        }
        .onChange(of: game.isShowingCompletedTrick) { _, newValue in
            print("🎯 GameBoardCenterSection - isShowingCompletedTrick changed to: \(newValue)")
        }
    }
}

// MARK: - Helper Views

struct CompletedTrickView: View {
    let cards: [PlayerCard]
    let game: Game
    let settings: GameSettings
    let gameRules: GameRules
    
    var body: some View {
        VStack(spacing: 8) {
            // Debug info block (conditional on settings.showDebugInfo)
            if settings.showDebugInfo {
                VStack(spacing: 2) {
                    Text("CompletedTrickView Debug:")
                    Text("Cards count: \(cards.count)")
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        Text("Card \(index): \(card.displayName)")
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
            }
            
            // Actual cards display
            HStack(spacing: 8) {
                ForEach(cards, id: \.id) { card in
                    VStack(spacing: 4) {
                        // Try to show the card image first
                        Image(card.imageName)
                            .resizable()
                            .aspectRatio(2.5/3.5, contentMode: .fit)
                            .frame(width: 60, height: 90)
                            .background(Color.white)
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                            .onAppear {
                                print("🎯 Loading image for card: \(card.displayName) with imageName: \(card.imageName)")
                            }
                        
                        // Fallback text display if image fails
                        VStack(spacing: 2) {
                            Text(card.displayName)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("ID: \(card.id)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60)
                        .padding(4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                    }
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)
        }
        .onAppear {
            print("🎯 CompletedTrickView appeared with \(cards.count) cards:")
            for (index, card) in cards.enumerated() {
                print("   Card \(index): \(card.displayName) (ID: \(card.id))")
            }
        }
        .onChange(of: cards.count) { _, newCount in
            print("🎯 CompletedTrickView cards count changed to: \(newCount)")
            print("   Cards: \(cards.map { $0.displayName })")
        }
    }
}

/// TrickView - Displays the current trick
struct TrickView: View {
    let cards: [PlayerCard]
    let game: Game
    let settings: GameSettings
    let gameRules: GameRules
    
    var body: some View {
        VStack(spacing: 8) {
            // Debug info block (conditional on settings.showDebugInfo)
            if settings.showDebugInfo {
                VStack(spacing: 2) {
                    Text("TrickView Debug:")
                    Text("Cards count: \(cards.count)")
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        Text("Card \(index): \(card.displayName)")
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
            }
            
            // Actual cards display
            HStack(spacing: 8) {
                ForEach(cards, id: \.id) { card in
                    VStack(spacing: 4) {
                        // Try to show the card image first
                        Image(card.imageName)
                            .resizable()
                            .aspectRatio(2.5/3.5, contentMode: .fit)
                            .frame(width: 60, height: 90)
                            .background(Color.white)
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                            .onAppear {
                                print("🎯 Loading image for card: \(card.displayName) with imageName: \(card.imageName)")
                            }
                        
                        // Fallback text display if image fails
                        VStack(spacing: 2) {
                            Text(card.displayName)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("ID: \(card.id)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60)
                        .padding(4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                    }
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)
        }
        .onAppear {
            print("🎯 TrickView appeared with \(cards.count) cards:")
            for (index, card) in cards.enumerated() {
                print("   Card \(index): \(card.displayName) (ID: \(card.id))")
            }
        }
        .onChange(of: cards.count) { _, newCount in
            print("🎯 TrickView cards count changed to: \(newCount)")
            print("   Cards: \(cards.map { $0.displayName })")
        }
    }
}

/// GameDrawPileView - Displays the draw pile
struct GameDrawPileView: View {
    let game: Game
    
    var body: some View {
        VStack(spacing: 4) {
            // Draw pile cards
            ZStack {
                ForEach(0..<min(3, game.deck.cards.count), id: \.self) { index in
                    CardBackView { }
                        .frame(width: 40, height: 60)
                        .offset(x: CGFloat(index) * 2, y: CGFloat(index) * 2)
                }
            }
            
            Text("\(game.deck.cards.count)")
                .font(.caption2)
                .foregroundColor(.white)
        }
        .position(x: 100, y: 100) // Position in top-left area
    }
} 
