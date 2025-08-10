import SwiftUI

/// GameBoardViewState2 - Centralized state management for GameBoardView2
/// 
/// This class manages all view-specific state, keeping the main view clean
/// and enabling better testing and state management.
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
    
    // MARK: - Card Animation States
    @Published var isPlayingCard = false
    @Published var playedCard: PlayerCard?
    @Published var isDrawingCard = false
    @Published var drawnCard: PlayerCard?
    @Published var cardAnimationDuration: Double = 0.5
    
    // MARK: - Drag and Drop States
    @Published var draggedOverCard: PlayerCard?
    @Published var isDragging = false
    
    // MARK: - Initialization
    
    init() {
        setupNotificationObservers()
    }
    
    deinit {
        // Remove notification observers immediately
        removeNotificationObservers()
    }
    
    // MARK: - Notification Setup
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .cardPlayed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let card = notification.object as? PlayerCard {
                Task { @MainActor in
                    self?.startCardPlayAnimation(with: card)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .cardDrawn,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let card = notification.object as? PlayerCard {
                Task { @MainActor in
                    self?.startCardDrawAnimation(with: card)
                }
            }
        }
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: .cardPlayed, object: nil)
        NotificationCenter.default.removeObserver(self, name: .cardDrawn, object: nil)
    }
    
    // MARK: - Public Methods
    
    /// Clear all selected cards
    @MainActor
    func clearSelectedCards() {
        selectedCards.removeAll()
    }
    
    /// Add a card to selection (with validation)
    @MainActor
    func selectCard(_ card: PlayerCard) {
        if !selectedCards.contains(card) && selectedCards.count < 4 {
            selectedCards.append(card)
        }
    }
    
    /// Remove a card from selection
    @MainActor
    func deselectCard(_ card: PlayerCard) {
        selectedCards.removeAll { $0 == card }
    }
    
    /// Show meld options sheet
    @MainActor
    func showMeldOptions() {
        showingMeldOptions = true
    }
    
    /// Show settings sheet
    @MainActor
    func showSettings() {
        showingSettings = true
    }
    
    /// Show badge legend sheet
    @MainActor
    func showBadgeLegend() {
        showingBadgeLegend = true
    }
    
    /// Trigger meld button shake animation
    @MainActor
    func triggerMeldButtonShake() {
        shakeMeldButton.toggle()
    }
    
    /// Show invalid meld message
    @MainActor
    func showInvalidMeldMessage() {
        showInvalidMeld = true
    }
    
    /// Start draw card animation
    @MainActor
    func startDrawAnimation(with card: PlayerCard) {
        animatingDrawnCard = card
        showDrawAnimation = true
    }
    
    /// Stop draw card animation
    @MainActor
    func stopDrawAnimation() {
        showDrawAnimation = false
        animatingDrawnCard = nil
    }
    
    /// Start card play animation
    @MainActor
    func startCardPlayAnimation(with card: PlayerCard) {
        playedCard = card
        isPlayingCard = true
        
        // Auto-stop animation after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + cardAnimationDuration) {
            self.stopCardPlayAnimation()
        }
    }
    
    /// Stop card play animation
    @MainActor
    func stopCardPlayAnimation() {
        isPlayingCard = false
        playedCard = nil
    }
    
    /// Start card draw animation
    @MainActor
    func startCardDrawAnimation(with card: PlayerCard) {
        drawnCard = card
        isDrawingCard = true
        
        // Auto-stop animation after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + cardAnimationDuration) {
            self.stopCardDrawAnimation()
        }
    }
    
    /// Stop card draw animation
    @MainActor
    func stopCardDrawAnimation() {
        isDrawingCard = false
        drawnCard = nil
    }
    
    // MARK: - Drag and Drop Methods
    
    /// Sets the card being dragged over for visual feedback
    @MainActor
    func setDraggedOverCard(_ card: PlayerCard?) {
        draggedOverCard = card
    }
    
    /// Clears the dragged over card state
    @MainActor
    func clearDraggedOverCard() {
        draggedOverCard = nil
    }
    
    /// Sets the dragging state
    @MainActor
    func setDragging(_ isDragging: Bool) {
        self.isDragging = isDragging
    }
} 