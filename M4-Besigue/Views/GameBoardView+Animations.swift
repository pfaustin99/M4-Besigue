import SwiftUI

// MARK: - GameBoardView Animations Extension
extension GameBoardView {
    
    // MARK: - Animation Manager
    /// Manages all animations in the game board view
    class GameAnimationManager: ObservableObject {
        @Published var isCardAnimating = false
        @Published var animatingCard: PlayerCard?
        @Published var showDrawAnimation = false
        @Published var showInvalidMeld = false
        @Published var shakeMeldButton = false
        
        /// Plays a card animation
        /// - Parameters:
        ///   - card: The card to animate
        ///   - completion: Completion handler called when animation finishes
        func playCardAnimation(card: PlayerCard, completion: @escaping () -> Void) {
            animatingCard = card
            isCardAnimating = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + GameBoardConstants.animationDuration) {
                self.isCardAnimating = false
                self.animatingCard = nil
                completion()
            }
        }
        
        /// Plays a draw animation
        /// - Parameter completion: Completion handler called when animation finishes
        func playDrawAnimation(completion: @escaping () -> Void) {
            showDrawAnimation = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + GameBoardConstants.animationDuration) {
                self.showDrawAnimation = false
                completion()
            }
        }
        
        /// Plays an invalid meld animation
        func playInvalidMeldAnimation() {
            showInvalidMeld = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + GameBoardConstants.animationDuration) {
                self.showInvalidMeld = false
            }
        }
        
        /// Triggers meld button shake animation
        func triggerMeldButtonShake() {
            shakeMeldButton = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + GameBoardConstants.animationDuration) {
                self.shakeMeldButton = false
            }
        }
        
        /// Resets all animations to initial state
        func resetAnimations() {
            isCardAnimating = false
            animatingCard = nil
            showDrawAnimation = false
            showInvalidMeld = false
            shakeMeldButton = false
        }
    }
    
    // MARK: - Animation Views
    /// Creates an animated card view
    /// - Parameters:
    ///   - card: The card to animate
    ///   - isAnimating: Whether the card is currently animating
    /// - Returns: Animated card view
    func animatedCardView(card: PlayerCard, isAnimating: Bool) -> some View {
        CardView(
            card: card,
            isSelected: false,
            isPlayable: true,
            showHint: false
        ) {
            // Card tap action
        }
        .scaleEffect(isAnimating ? 1.2 : 1.0)
        .rotationEffect(.degrees(isAnimating ? 5 : 0))
        .animation(.easeInOut(duration: GameBoardConstants.animationDuration), value: isAnimating)
    }
    
    /// Creates a draw animation view
    /// - Parameter card: The card being drawn
    /// - Returns: Draw animation view
    func drawAnimationView(card: PlayerCard) -> some View {
        VStack {
            Text("Drawing...")
                .font(.caption)
                .foregroundColor(.white)
                .padding(4)
                .background(GameBoardConstants.Colors.overlayBackground)
                .cornerRadius(4)
            
            CardView(
                card: card,
                isSelected: false,
                isPlayable: false,
                showHint: false
            ) {
                // No action during animation
            }
            .scaleEffect(1.1)
            .animation(.easeInOut(duration: GameBoardConstants.animationDuration), value: true)
        }
    }
    
    /// Creates an invalid meld animation view
    /// - Returns: Invalid meld animation view
    func invalidMeldAnimationView() -> some View {
        Text("Invalid Meld!")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(8)
            .background(Color.red.opacity(0.8))
            .cornerRadius(GameBoardConstants.cornerRadius)
            .scaleEffect(viewState.showInvalidMeld ? 1.2 : 1.0)
            .animation(.easeInOut(duration: GameBoardConstants.animationDuration), value: viewState.showInvalidMeld)
    }
    
    /// Creates a meld button with shake animation
    /// - Parameter action: Action to perform when button is tapped
    /// - Returns: Animated meld button
    func animatedMeldButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Meld")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(8)
                .background(GameBoardConstants.Colors.primaryGreen)
                .cornerRadius(GameBoardConstants.cornerRadius)
        }
        .scaleEffect(viewState.shakeMeldButton ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1).repeatCount(3), value: viewState.shakeMeldButton)
    }
    
    // MARK: - Transition Animations
    /// Creates a card transition animation
    /// - Parameters:
    ///   - card: The card to transition
    ///   - fromPosition: Starting position
    ///   - toPosition: Ending position
    /// - Returns: Transition animation view
    func cardTransitionAnimation(card: PlayerCard, fromPosition: CGPoint, toPosition: CGPoint) -> some View {
        CardView(
            card: card,
            isSelected: false,
            isPlayable: false,
            showHint: false
        ) {
            // No action during transition
        }
        .position(fromPosition)
        .animation(.easeInOut(duration: GameBoardConstants.animationDuration), value: toPosition)
        .onAppear {
            // Trigger position change
        }
    }
    
    // MARK: - Loading Animations
    /// Creates a loading spinner animation
    /// - Returns: Loading spinner view
    func loadingSpinnerView() -> some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: GameBoardConstants.Colors.primaryGold))
            .scaleEffect(1.5)
            .padding()
            .background(GameBoardConstants.Colors.overlayBackground)
            .cornerRadius(GameBoardConstants.cornerRadius)
    }
    
    /// Creates a pulsing animation view
    /// - Parameter content: The content to animate
    /// - Returns: Pulsing animated view
    func pulsingAnimationView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .scaleEffect(viewState.showDrawAnimation ? 1.1 : 1.0)
            .opacity(viewState.showDrawAnimation ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewState.showDrawAnimation)
    }
    
    // MARK: - Success/Failure Animations
    /// Creates a success animation view
    /// - Parameter message: Success message to display
    /// - Returns: Success animation view
    func successAnimationView(message: String) -> some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundColor(.green)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding()
        .background(GameBoardConstants.Colors.overlayBackground)
        .cornerRadius(GameBoardConstants.cornerRadius)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: true)
    }
    
    /// Creates a failure animation view
    /// - Parameter message: Failure message to display
    /// - Returns: Failure animation view
    func failureAnimationView(message: String) -> some View {
        VStack {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding()
        .background(GameBoardConstants.Colors.overlayBackground)
        .cornerRadius(GameBoardConstants.cornerRadius)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: true)
    }
} 