import SwiftUI

/// Consolidated state management class for GameBoardView
/// Handles all view-related state including selections, UI visibility, and animations
class GameBoardViewState: ObservableObject {
    // MARK: - Card Selection State
    @Published var selectedCards: [PlayerCard] = []
    
    // MARK: - UI Visibility State
    @Published var showingMeldOptions = false
    @Published var showingSettings = false
    @Published var showingBadgeLegend = false
    @Published var isSinglePlayerMode = false
    
    // MARK: - Animation States
    @Published var showInvalidMeld = false
    @Published var shakeMeldButton = false
    @Published var showDrawAnimation = false
    @Published var animatingDrawnCard: PlayerCard?
    @Published var isCardAnimating = false
    @Published var animatingCard: PlayerCard?
    
    // MARK: - Tap Handling State
    @Published var tapCount: Int = 0
    @Published var lastTapTime: Date = Date()
    
    // MARK: - Namespace for Animations
    @Namespace var drawPileNamespace
    
    // MARK: - Card Selection Methods
    /// Toggles the selection state of a card
    /// - Parameter card: The card to toggle selection for
    func toggleCardSelection(_ card: PlayerCard) {
        if let index = selectedCards.firstIndex(of: card) {
            selectedCards.remove(at: index)
        } else {
            selectedCards.append(card)
        }
    }
    
    /// Adds a card to the selection
    /// - Parameter card: The card to add to selection
    func addCardToSelection(_ card: PlayerCard) {
        if !selectedCards.contains(card) {
            selectedCards.append(card)
        }
    }
    
    /// Removes a card from the selection
    /// - Parameter card: The card to remove from selection
    func removeCardFromSelection(_ card: PlayerCard) {
        selectedCards.removeAll { $0 == card }
    }
    
    /// Clears all selected cards
    func clearSelection() {
        selectedCards.removeAll()
    }
    
    /// Checks if a card is currently selected
    /// - Parameter card: The card to check
    /// - Returns: True if the card is selected
    func isCardSelected(_ card: PlayerCard) -> Bool {
        return selectedCards.contains(card)
    }
    
    // MARK: - Animation Control Methods
    /// Triggers the invalid meld animation
    func triggerInvalidMeldAnimation() {
        showInvalidMeld = true
        DispatchQueue.main.asyncAfter(deadline: .now() + GameBoardConstants.animationDuration) {
            self.showInvalidMeld = false
        }
    }
    
    /// Triggers the meld button shake animation
    func triggerMeldButtonShake() {
        shakeMeldButton = true
        DispatchQueue.main.asyncAfter(deadline: .now() + GameBoardConstants.animationDuration) {
            self.shakeMeldButton = false
        }
    }
    
    /// Starts the draw animation
    /// - Parameter card: The card being drawn
    func startDrawAnimation(with card: PlayerCard) {
        animatingDrawnCard = card
        showDrawAnimation = true
    }
    
    /// Stops the draw animation
    func stopDrawAnimation() {
        animatingDrawnCard = nil
        showDrawAnimation = false
    }
    
    /// Resets all animation states
    func resetAnimations() {
        showInvalidMeld = false
        shakeMeldButton = false
        showDrawAnimation = false
        animatingDrawnCard = nil
        isCardAnimating = false
        animatingCard = nil
    }
    
    // MARK: - UI State Methods
    /// Shows the meld options sheet
    func showMeldOptions() {
        showingMeldOptions = true
    }
    
    /// Hides the meld options sheet
    func hideMeldOptions() {
        showingMeldOptions = false
    }
    
    /// Shows the settings sheet
    func showSettings() {
        showingSettings = true
    }
    
    /// Hides the settings sheet
    func hideSettings() {
        showingSettings = false
    }
    
    /// Shows the badge legend sheet
    func showBadgeLegend() {
        showingBadgeLegend = true
    }
    
    /// Hides the badge legend sheet
    func hideBadgeLegend() {
        showingBadgeLegend = false
    }
    
    /// Toggles single player mode
    func toggleSinglePlayerMode() {
        isSinglePlayerMode.toggle()
    }
    
    // MARK: - Tap Handling Methods
    /// Handles tap events for double-tap detection
    /// - Parameter action: The action to perform on double tap
    func handleTap(action: @escaping () -> Void) {
        let now = Date()
        if now.timeIntervalSince(lastTapTime) < 0.3 {
            // Double tap detected
            action()
            tapCount = 0
        } else {
            // Single tap
            tapCount += 1
        }
        lastTapTime = now
    }
    
    /// Resets tap count
    func resetTapCount() {
        tapCount = 0
    }
    
    // MARK: - State Reset Methods
    /// Resets all state to initial values
    func resetAllState() {
        clearSelection()
        resetAnimations()
        hideMeldOptions()
        hideSettings()
        hideBadgeLegend()
        resetTapCount()
        isSinglePlayerMode = false
    }
} 