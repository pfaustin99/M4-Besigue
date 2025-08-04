import SwiftUI

/// GameBoardViewState2 - Centralized state management for GameBoardView2
/// 
/// This class manages all view-specific state, keeping the main view clean
/// and enabling better testing and state management.
@MainActor
class GameBoardViewState2: ObservableObject {
    // MARK: - Card Selection
    @Published var selectedCards: [PlayerCard] = []
    
    // MARK: - UI State
    @Published var showingMeldOptions = false
    @Published var showingSettings = false
    @Published var showingBadgeLegend = false
    @Published var showDrawAnimation = false
    @Published var animatingDrawnCard: PlayerCard?
    
    // MARK: - Animation State
    @Published var shakeMeldButton = false
    @Published var showInvalidMeld = false
    
    // MARK: - Public Methods
    
    /// Clear all selected cards
    func clearSelectedCards() {
        selectedCards.removeAll()
    }
    
    /// Add a card to selection (with validation)
    func selectCard(_ card: PlayerCard) {
        if !selectedCards.contains(card) && selectedCards.count < 4 {
            selectedCards.append(card)
        }
    }
    
    /// Remove a card from selection
    func deselectCard(_ card: PlayerCard) {
        selectedCards.removeAll { $0 == card }
    }
    
    /// Show meld options sheet
    func showMeldOptions() {
        showingMeldOptions = true
    }
    
    /// Show settings sheet
    func showSettings() {
        showingSettings = true
    }
    
    /// Show badge legend sheet
    func showBadgeLegend() {
        showingBadgeLegend = true
    }
    
    /// Trigger meld button shake animation
    func triggerMeldButtonShake() {
        shakeMeldButton.toggle()
    }
    
    /// Show invalid meld message
    func showInvalidMeldMessage() {
        showInvalidMeld = true
    }
    
    /// Start draw card animation
    func startDrawAnimation(with card: PlayerCard) {
        animatingDrawnCard = card
        showDrawAnimation = true
    }
    
    /// Stop draw card animation
    func stopDrawAnimation() {
        showDrawAnimation = false
        animatingDrawnCard = nil
    }
} 