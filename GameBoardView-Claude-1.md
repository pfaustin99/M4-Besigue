# GameBoardView Refactoring Requirements for Cursor

## 1. File Structure Reorganization

**Task**: Break down the large GameBoardView.swift file into smaller, focused files:

```
GameBoardView/
├── GameBoardView.swift (main view)
├── GameBoardView+PlayerViews.swift
├── GameBoardView+Animations.swift
├── GameBoardView+Layout.swift
├── GameBoardView+Actions.swift
└── GameBoardViewState.swift
```

**Requirements**:
- Move all player-related view methods to `GameBoardView+PlayerViews.swift`
- Move all animation-related code to `GameBoardView+Animations.swift`
- Move layout calculation methods to `GameBoardView+Layout.swift`
- Move action handlers to `GameBoardView+Actions.swift`
- Create a consolidated state management class in `GameBoardViewState.swift`

## 2. Create Constants Structure

**Task**: Replace all magic numbers with named constants

```swift
private struct GameBoardConstants {
    static let cardWidth: CGFloat = 80
    static let cardHeight: CGFloat = 120
    static let animationDuration: Double = 0.6
    static let maxVisibleCards = 16
    static let stackOffset: CGFloat = 2
    static let maxStackDepth: Int = 16
    
    struct RadiusFactors {
        static let avatar: CGFloat = 0.85
        static let hand: CGFloat = 0.65
        static let meld: CGFloat = 0.45
    }
    
    struct PlayerAngles {
        static let twoPlayer: [Double] = [90, 270]
        static let threePlayer: [Double] = [90, 210, 330]
        static let fourPlayer: [Double] = [90, 180, 270, 0]
    }
}
```

## 3. Create Animation Manager

**Task**: Extract all animation logic into a dedicated manager class

```swift
class GameAnimationManager: ObservableObject {
    @Published var isCardAnimating = false
    @Published var animatingCard: PlayerCard?
    @Published var showDrawAnimation = false
    @Published var showInvalidMeld = false
    @Published var shakeMeldButton = false
    
    func playCardAnimation(card: PlayerCard, completion: @escaping () -> Void)
    func playDrawAnimation(completion: @escaping () -> Void)
    func playInvalidMeldAnimation()
    func resetAnimations()
}
```

## 4. Create Layout Configuration System

**Task**: Create a structured layout system to replace complex positioning logic

```swift
struct PlayerLayoutConfig {
    let center: CGPoint
    let minSide: CGFloat
    let playerCount: Int
    
    var radiusFactors: (avatar: CGFloat, hand: CGFloat, meld: CGFloat)
    var angles: [Double]
    
    func playerPosition(for index: Int, radiusFactor: CGFloat) -> CGPoint
    func isHorizontalLayout(for index: Int) -> Bool
    func cardRotation(for index: Int) -> Double
}
```

## 5. Consolidate View State

**Task**: Create a single state management class for all view-related state

```swift
class GameBoardViewState: ObservableObject {
    @Published var selectedCards: [PlayerCard] = []
    @Published var showingMeldOptions = false
    @Published var showingSettings = false
    @Published var showingBadgeLegend = false
    @Published var isSinglePlayerMode = false
    
    // Animation states
    @Published var showInvalidMeld = false
    @Published var shakeMeldButton = false
    @Published var showDrawAnimation = false
    @Published var animatingDrawnCard: PlayerCard?
    
    func handleScoreTap()
    func resetSelection()
    func toggleCardSelection(_ card: PlayerCard)
}
```

## 6. Error Handling Improvements

**Task**: Add comprehensive error handling throughout the view

```swift
enum GameBoardError: LocalizedError {
    case cannotPlayCard
    case invalidCardSelection
    case animationFailed
    
    var errorDescription: String? {
        switch self {
        case .cannotPlayCard: return "Cannot play card at this time"
        case .invalidCardSelection: return "Invalid card selection"
        case .animationFailed: return "Animation failed to complete"
        }
    }
}

private func handleError(_ error: GameBoardError) {
    // Show user-friendly error message
}
```

## 7. Performance Optimizations

**Task**: Implement performance improvements

- Add `@ViewBuilder` to complex view methods
- Use `LazyVStack`/`LazyHStack` for large lists
- Implement view caching for expensive calculations
- Add `@State` caching for computed properties that don't change often

```swift
@State private var cachedPlayerPositions: [Int: CGPoint] = [:]
@State private var lastGeometrySize: CGSize = .zero

private func updateCachedPositions(geometry: GeometryProxy) {
    guard geometry.size != lastGeometrySize else { return }
    // Recalculate and cache positions
}
```

## 8. Accessibility Improvements

**Task**: Add comprehensive accessibility support

```swift
// Add to all interactive elements:
.accessibilityLabel("Draw pile with \(game.deck.remainingCount) cards")
.accessibilityHint("Double tap to draw a card")
.accessibilityAddTraits(.isButton)

// Add to card views:
.accessibilityLabel("\(card.displayName)")
.accessibilityValue(isSelected ? "Selected" : "Not selected")
```

## 9. Code Documentation

**Task**: Add comprehensive documentation

```swift
/// Displays the main game board with all players, cards, and interactions
/// - Parameters:
///   - game: The main game state object
///   - settings: User preferences and settings
///   - gameRules: Game rules and configuration
///   - onEndGame: Closure called when ending the game
struct GameBoardView: View {
    // ... existing code
}
```

## 10. Method Simplification

**Task**: Break down complex methods into smaller, focused functions

**Target methods to refactor**:
- `concentricSquaresContent` (300+ lines) → Split into 3-4 smaller methods
- `gamePlayerHandView` (100+ lines) → Split into 2-3 methods
- `actionButtonsView` (50+ lines) → Split logic into separate methods

**Example refactoring**:
```swift
// Instead of one large method:
private func concentricSquaresContent(playerCount: Int, geometry: GeometryProxy) -> some View {
    // 300+ lines of code
}

// Break into:
private func createPlayerLayout(config: PlayerLayoutConfig) -> some View
private func positionPlayersInCircle(playerCount: Int, geometry: GeometryProxy) -> some View
private func createTrickArea(at center: CGPoint) -> some View
```

## Implementation Priority

1. **High Priority**: File structure reorganization, constants extraction, state consolidation
2. **Medium Priority**: Animation manager, layout configuration, error handling
3. **Low Priority**: Performance optimizations, accessibility, documentation

## Testing Requirements

After refactoring:
- All existing functionality should work identically
- No performance regressions
- All animations should work as before
- Game state should be preserved correctly

## Cursor-Specific Instructions

1. **Preserve existing functionality** - Don't change game logic, only improve structure
2. **Maintain SwiftUI best practices** - Use @StateObject, @ObservedObject correctly
3. **Keep the same visual appearance** - UI should look identical after refactoring
4. **Add TODO comments** for any complex refactoring that needs manual review
5. **Use meaningful variable names** and follow Swift naming conventions
6. **Add unit tests** for new utility classes and methods where possible

