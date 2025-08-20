import SwiftUI

// MARK: - Shake Effect Modifier
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(animatableData * .pi * CGFloat(6)), y: 0))
    }
}

/// GameBoardCenterSection - Center section containing the main game area
struct GameBoardCenterSection: View {
    @ObservedObject var game: Game
    let settings: GameSettings
    let gameRules: GameRules
    let geometry: GeometryProxy
    
    // Dynamic sizing for trick area (Option B)
    private var trickAreaMaxWidth: CGFloat {
        let w = geometry.size.width
        return w < 768 ? w * 0.9 : min(w * 0.6, 720)
    }
    private let trickAreaAspect: CGFloat = 4.0 / 3.0

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
                .frame(maxWidth: trickAreaMaxWidth)
                .aspectRatio(trickAreaAspect, contentMode: .fit)
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
                .frame(maxWidth: trickAreaMaxWidth)
                .aspectRatio(trickAreaAspect, contentMode: .fit)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: game.currentTrick.count)
            } else {
                // Empty state - minimal and clean
                Color.clear
                    .frame(maxWidth: trickAreaMaxWidth)
                    .aspectRatio(trickAreaAspect, contentMode: .fit)
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
    @State private var winningCardPopped = false
    @State private var winningCardShaking = false
    @State private var winningCardRotating = false
    @State private var animationPhase: AnimationPhase = .initial
    @State private var animationTimer: Timer?
    
    enum AnimationPhase {
        case initial, popped, shaking, rotating, complete
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card display - natural stacking like real cards on a table
            ZStack {
                // Display cards in natural stacked order (winning card pops to top after animation)
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    CardView(card: card, onTap: {}) // No-op for display-only cards
                        .frame(width: trickCardSize.width, height: trickCardSize.height)
                        .rotationEffect(.degrees(naturalCardRotation(for: index)))
                        .offset(naturalCardOffset(for: index))
                        .zIndex(winningCardPopped && game.completedTrickWinnerIndex == index 
                            ? Double(cards.count + 10)  // Winning card on very top
                            : Double(index)) // Normal stacking order: first card on bottom, last card on top
                        .scaleEffect(winningCardPopped && game.completedTrickWinnerIndex == index ? 1.1 : 1.0)
                    //    .modifier(ShakeEffect(animatableData: winningCardShaking && game.completedTrickWinnerIndex == index ? 1 : 0))
                   //     .rotationEffect(.degrees(winningCardRotating && game.completedTrickWinnerIndex == index ? 360 : 0))
                        .animation(.easeInOut(duration: TrickAnimationTiming.winningCardRotationDuration), value: winningCardRotating)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: winningCardPopped)
                        .animation(.easeInOut(duration: TrickAnimationTiming.winningCardShakeDuration), value: winningCardShaking)
                }
            }
        }
        .onAppear {
            print("🎭 CompletedTrickView appeared")
            print("   cards.count: \(cards.count)")
            print("   isShowingCompletedTrick: \(game.isShowingCompletedTrick)")
            print("   cards == completedTrick: \(cards == game.completedTrick)")
            print("   animationPhase: \(animationPhase)")
            
            // Start winning card animation sequence
            startWinningCardAnimation()
        }
        .onChange(of: cards.count) { _, newCount in
            print("🎭 CompletedTrickView - cards.count changed to: \(newCount)")
            print("   isShowingCompletedTrick: \(game.isShowingCompletedTrick)")
            print("   cards == completedTrick: \(cards == game.completedTrick)")
            print("   animationPhase: \(animationPhase)")
            
            // Only start animation if this is the completed trick AND we haven't already started it
            if game.isShowingCompletedTrick && cards == game.completedTrick && animationPhase == .initial {
                print("🎭 Starting animation from onChange trigger")
                startWinningCardAnimation()
            } else {
                print("🎭 Animation NOT started from onChange - conditions not met")
            }
        }
        .onDisappear {
            // Clean up timer and reset animation state
            animationTimer?.invalidate()
            resetAnimation()
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
        let baseRotation = -35.0 // Increased base rotation for more dramatic look - wss -30
        let rotationVariation = Double(index) * 20.0 // Much larger variation per card - was 12
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
    
    // Start the winning card animation sequence
    private func startWinningCardAnimation() {
        print("🎉 startWinningCardAnimation() called")
        print("   isShowingCompletedTrick: \(game.isShowingCompletedTrick)")
        print("   cards == completedTrick: \(cards == game.completedTrick)")
        print("   animationPhase: \(animationPhase)")
        
        // Only start if this is the completed trick AND we're in initial state
        guard game.isShowingCompletedTrick && cards == game.completedTrick && animationPhase == .initial else { 
            print("🎉 Animation NOT started - guard condition failed")
            return 
        }
        
        print("🎉 Starting winning card animation for completed trick!")
        
        // Phase 1: Pop to top
        DispatchQueue.main.asyncAfter(deadline: .now() + TrickAnimationTiming.winningCardPopDelay) {
            guard animationPhase == .initial else { return }
            winningCardPopped = true
            animationPhase = .popped
        }
        
        // Phase 2: Start shaking
  /*      DispatchQueue.main.asyncAfter(deadline: .now() + TrickAnimationTiming.winningCardPopDelay + 0.6) {
            guard animationPhase == .popped else { return }
            winningCardShaking = true
            animationPhase = .shaking
        }
        
        // Phase 3: Start rotation
       DispatchQueue.main.asyncAfter(deadline: .now() + TrickAnimationTiming.winningCardPopDelay + 1.2) {
            guard animationPhase == .shaking else { return }
            winningCardRotating = true
            animationPhase = .rotating
        } */
        
        // Phase 4: Animation complete
        DispatchQueue.main.asyncAfter(deadline: .now() + TrickAnimationTiming.winningCardPopDelay + 2.0) {
            guard animationPhase == .rotating else { return }
            animationPhase = .complete
        }
    }
    
    // Reset animation state
    private func resetAnimation() {
        winningCardPopped = false
        winningCardShaking = false
        winningCardRotating = false
        animationPhase = .initial
    }
    
    // Timer to control winning card visibility (kept for compatibility)
    private func startWinningCardTimer() {
        // Cancel existing timer
        animationTimer?.invalidate()
        
        // Set new timer for the total animation duration
        animationTimer = Timer.scheduledTimer(withTimeInterval: TrickAnimationTiming.winningCardDisplayDuration, repeats: false) { _ in
            // Animation sequence is handled by the new animation system
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
