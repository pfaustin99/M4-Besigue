import SwiftUI

// MARK: - GameBoardView Action Handlers Extension
extension GameBoardView {
    
    // MARK: - Card Actions
    /// Handles card selection when a card is tapped
    /// - Parameter card: The card that was tapped
    func handleCardSelection(_ card: PlayerCard) {
        viewState.toggleCardSelection(card)
    }
    
    /// Handles when a card is played (double-tap)
    /// - Parameter card: The card that was played
    func handleCardPlayed(_ card: PlayerCard) {
        guard game.canPlayCard() else {
            viewState.triggerInvalidMeldAnimation()
            return
        }
        
        game.playCard(card, from: game.currentPlayer)
        viewState.clearSelection()
    }
    
    // MARK: - Game Control Actions
    /// Handles the end game action
    func handleEndGame() {
        onEndGame()
    }
    
    /// Handles starting a new game
    func handleStartNewGame() {
        game.startNewGame()
    }
    
    /// Handles saving the current game
    func handleSaveGame() {
        // TODO: Implement actual save game functionality
        // For now, this is a placeholder
        print("Save game functionality to be implemented")
    }
    
    /// Handles showing settings
    func handleShowSettings() {
        viewState.showSettings()
    }
    
    // MARK: - Meld Actions
    /// Handles the meld button action
    func handleMeldButton() {
        guard !viewState.selectedCards.isEmpty else {
            viewState.triggerMeldButtonShake()
            return
        }
        
        // TODO: Implement proper meld validation
        // For now, just show meld options
        viewState.showMeldOptions()
    }
    
    /// Handles drawing a card from the deck
    func handleDrawCard() {
        // TODO: Implement proper draw card validation
        // For now, just trigger the animation
        let exampleCard = Card(suit: .hearts, value: .ace)
        viewState.startDrawAnimation(with: PlayerCard(card: exampleCard))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + GameBoardConstants.animationDuration) {
            self.viewState.stopDrawAnimation()
        }
    }
    
    // MARK: - Score Actions
    /// Handles tapping on the score display
    func handleScoreTap() {
        viewState.showBadgeLegend()
    }
    
    // MARK: - AI Actions
    /// Handles AI player actions
    func handleAIAction() {
        guard game.currentPlayerIndex != 0 else { return }
        
        // TODO: Implement proper AI move
        // For now, just advance to next player
        print("AI move would be implemented here")
    }
    
    // MARK: - Animation Actions
    /// Handles animation completion callbacks
    func handleAnimationCompletion() {
        viewState.resetAnimations()
    }
    
    // MARK: - Sheet Dismissal Actions
    /// Handles dismissing the meld options sheet
    func handleMeldOptionsDismiss() {
        viewState.hideMeldOptions()
        viewState.clearSelection()
    }
    
    /// Handles dismissing the settings sheet
    func handleSettingsDismiss() {
        viewState.hideSettings()
    }
    
    /// Handles dismissing the badge legend sheet
    func handleBadgeLegendDismiss() {
        viewState.hideBadgeLegend()
    }
    
    // MARK: - Error Handling Actions
    /// Handles game errors
    /// - Parameter error: The error that occurred
    func handleGameError(_ error: Error) {
        // TODO: Implement proper error handling
        print("Game error: \(error.localizedDescription)")
    }
    
    /// Handles invalid actions
    /// - Parameter action: Description of the invalid action
    func handleInvalidAction(_ action: String) {
        // TODO: Implement user feedback for invalid actions
        print("Invalid action: \(action)")
    }
} 