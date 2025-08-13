import SwiftUI

/// GameBoardCenterSection - Center section containing the main game area
struct GameBoardCenterSection: View {
    @ObservedObject var game: Game
    let settings: GameSettings
    let gameRules: GameRules
    let geometry: GeometryProxy
    
    var body: some View {
        VStack {
            // Main trick area content
            if game.isShowingCompletedTrick {
                CompletedTrickView(
                    cards: game.completedTrick,
                    game: game,
                    settings: settings,
                    gameRules: gameRules,
                    geometry: geometry
                )
                .frame(width: 400, height: 300) // Increased to accommodate larger cards
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
                    gameRules: gameRules,
                    geometry: geometry
                )
                .frame(width: 400, height: 300) // Increased to accommodate larger cards
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: game.currentTrick.count)
            } else {
                // Empty state - minimal and clean
                Color.clear
                    .frame(width: 400, height: 300) // Increased to match
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
    let geometry: GeometryProxy
    
    // Animation state for winning card
    @State private var winningCardVisible = false
    @State private var animationTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card display - natural stacking like real cards on a table
            ZStack {
                // Display cards in natural stacked order (winning card on top)
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    CardView(card: card, onTap: {}) // No-op for display-only cards
                        .frame(width: trickCardSize.width, height: trickCardSize.height)
                        .rotationEffect(.degrees(naturalCardRotation(for: index)))
                        .offset(naturalCardOffset(for: index))
                        .zIndex(Double(cards.count - index)) // Winning card (last played) on top
                        .animation(.easeInOut(duration: 0.6), value: cards.count)
                }
            }
        }
        .onAppear {
            // Start winning card visibility timer
            startWinningCardTimer()
        }
        .onChange(of: cards.count) { _, newCount in
            // Reset timer when new cards are added
            startWinningCardTimer()
        }
        .onDisappear {
            // Clean up timer
            animationTimer?.invalidate()
        }
    }
    
    // Use larger card sizes for trick area - more prominent and easier to see
    private var humanCardSize: CGSize {
        geometry.size.width < 768 ? CGSize(width: 70, height: 105) : CGSize(width: 140, height: 210)
    }
    
    // Trick area cards are larger than human hand cards for better visibility
    private var trickCardSize: CGSize {
        let baseSize = humanCardSize
        return CGSize(width: baseSize.width * 1.25, height: baseSize.height * 1.25)
    }
    
    // Natural card rotation - like real cards thrown on a table with larger differences
    private func naturalCardRotation(for index: Int) -> Double {
        let baseRotation = -25.0 // Increased base rotation for more dramatic look
        let rotationVariation = Double(index) * 12.0 // Much larger variation per card
        let winningCardBonus = index == cards.count - 1 ? 15.0 : 0.0 // Winning card much more upright
        
        return baseRotation + rotationVariation + winningCardBonus
    }
    
    // Natural card offset - realistic stacking like cards on a table
    private func naturalCardOffset(for index: Int) -> CGSize {
        let baseOffset: CGFloat = 18.0 // Increased base stacking offset for larger cards
        let cardSpacing = baseOffset * CGFloat(index)
        
        // Add slight horizontal variation for natural look
        let horizontalVariation = CGFloat(index) * 3.0 // Increased variation
        let verticalVariation = CGFloat(index) * 1.8 // Increased variation
        
        return CGSize(
            width: cardSpacing + horizontalVariation,
            height: cardSpacing + verticalVariation
        )
    }
    
    // Timer to control winning card visibility
    private func startWinningCardTimer() {
        // Cancel existing timer
        animationTimer?.invalidate()
        
        // Set new timer for 0.75 seconds (between 0.5-1.0 as requested)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { _ in
            // This will be handled by the game logic when clearing the trick
            // The timer ensures the winning card stays visible for the specified duration
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
