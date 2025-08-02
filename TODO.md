# M4-Besigue Implementation TODO

## Phase 1: Clean Up Current Implementation ✅ COMPLETE

### Remove Pre-initialization
- [x] Remove `initializeGame()` call from `onAppear` in HomePageView
- [x] Remove `setupDefaultConfigurationIfNeeded()` function
- [x] Keep only default `gameRules` initialization in HomePageView
- [x] Remove all debug logging from game initialization

### Simplify Play Button Flow
- [x] Simplify `startGame()` method to only:
  - Instantiate new Game with gameRules
  - Call startNewGame()
  - Set isGameActive = true
- [x] Remove complex state management and timing fixes
- [x] Remove DispatchQueue.main.async calls

### Clean up GameSettingsView Integration
- [x] Remove `initializeGame()` call from configuration save callback
- [x] Ensure configuration changes only update `gameRules` object
- [x] Remove any game creation from configuration save flow

### ✅ Phase 1 Results
- [x] No pre-initialization on app startup
- [x] Clean, simple startGame() method
- [x] Game only created when Play button is pressed
- [x] Configuration changes only update gameRules object
- [x] Build and test successful

## Phase 2: Implement Clean Game Initialization

### Update Game Constructor
- [ ] Ensure `Game(gameRules:)` reads all configuration parameters during initialization
- [ ] Add validation for configuration parameters during game creation
- [ ] Make game fully self-contained with its configuration
- [ ] Verify game constructor properly initializes all game state

### Simplify startGame() Method
- [ ] Implement clean startGame() method:
  ```swift
  private func startGame() {
      game = Game(gameRules: gameRules)  // Reads all config
      game?.startNewGame()               // Starts gameplay
      isGameActive = true                // Shows game board
  }
  ```

## Phase 3: Add GameBoard Controls

### End Game Button
- [ ] Add End Game button to GameBoardView
- [ ] Implement `onEndGame` callback to dismiss fullScreenCover
- [ ] Ensure clean return to HomePage
- [ ] Verify game state is properly discarded when ending game

### Save Game Button
- [ ] Add Save Game button to GameBoardView
- [ ] Implement placeholder function for future save functionality
- [ ] Ensure button doesn't affect current game state
- [ ] Add appropriate button styling and positioning

## Phase 4: Configuration Persistence

### Save Configuration to UserDefaults
- [ ] Save `gameRules` state to UserDefaults or similar storage
- [ ] Load configuration on app startup
- [ ] Ensure configuration persists across app launches
- [ ] Add configuration versioning for future compatibility

### Validation and Error Handling
- [ ] Add validation logic for configuration parameters
- [ ] Provide user feedback for invalid configurations
- [ ] Ensure robust error handling
- [ ] Add validation for player count, names, and game settings

## Phase 5: Testing & Refinement

### Test Complete Flow
- [ ] Test HomePage → Configure → Play → GameBoard → End Game → HomePage
- [ ] Verify configuration persistence across app restarts
- [ ] Test with different player counts (2, 3, 4 players)
- [ ] Test with different game settings and configurations
- [ ] Verify game state is properly initialized with correct player count

### Error Handling
- [ ] Test invalid configurations
- [ ] Test edge cases (0 players, invalid settings, etc.)
- [ ] Ensure graceful failure handling
- [ ] Add appropriate error messages and user feedback

### Performance & Memory
- [ ] Verify no memory leaks when creating/discarding games
- [ ] Test performance with multiple game sessions
- [ ] Ensure clean state management

## Future Enhancements (Post-Implementation)

### Save Game Functionality
- [ ] Implement actual save game functionality
- [ ] Design save game data structure
- [ ] Add load game functionality
- [ ] Implement save game management UI

### Additional Features
- [ ] Add game statistics tracking
- [ ] Implement game history
- [ ] Add sound effects and animations
- [ ] Enhance UI/UX based on user feedback

## Notes
- Focus on clean, simple implementation
- Single responsibility principle for all methods
- User-driven flow - game only exists when user wants to play
- Configuration persistence across app restarts
- Future-ready architecture for save game functionality