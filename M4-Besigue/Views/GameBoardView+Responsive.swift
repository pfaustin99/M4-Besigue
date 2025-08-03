import SwiftUI

// MARK: - Screen Size Categories
enum ScreenSizeCategory {
    case compact      // iPhone SE, small phones
    case regular      // Standard iPhones
    case large        // iPhone Pro Max, Plus models
    case tablet       // iPads
    case desktop      // Mac Catalyst
    
    static func categorize(width: CGFloat, height: CGFloat) -> ScreenSizeCategory {
        let minDimension = min(width, height)
        let _ = max(width, height)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            if minDimension < 375 {
                return .compact
            } else if minDimension < 428 {
                return .regular
            } else {
                return .large
            }
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            return .tablet
        } else {
            return .desktop
        }
    }
}

// MARK: - Dynamic Layout Configuration
struct DynamicLayoutConfig {
    let cardSize: CGFloat
    let padding: CGFloat
    let cornerRadius: CGFloat
    let fontSize: FontSizes
    let radiusFactors: RadiusFactors
    
    struct FontSizes {
        let title: CGFloat
        let body: CGFloat
        let caption: CGFloat
        let small: CGFloat
    }
    
    struct RadiusFactors {
        let avatar: CGFloat
        let hand: CGFloat
        let meld: CGFloat
    }
    
    static func config(for category: ScreenSizeCategory, geometry: GeometryProxy) -> DynamicLayoutConfig {
        let _ = min(geometry.size.width, geometry.size.height)
        let _ = max(geometry.size.width, geometry.size.height)
        
        switch category {
        case .compact:
            return DynamicLayoutConfig(
                cardSize: 0.7,
                padding: 8,
                cornerRadius: 6,
                fontSize: FontSizes(title: 16, body: 14, caption: 12, small: 10),
                radiusFactors: RadiusFactors(avatar: 0.8, hand: 0.6, meld: 0.4)
            )
        case .regular:
            return DynamicLayoutConfig(
                cardSize: 0.85,
                padding: 12,
                cornerRadius: 8,
                fontSize: FontSizes(title: 18, body: 16, caption: 14, small: 12),
                radiusFactors: RadiusFactors(avatar: 0.85, hand: 0.65, meld: 0.45)
            )
        case .large:
            return DynamicLayoutConfig(
                cardSize: 1.0,
                padding: 16,
                cornerRadius: 10,
                fontSize: FontSizes(title: 20, body: 18, caption: 16, small: 14),
                radiusFactors: RadiusFactors(avatar: 0.9, hand: 0.7, meld: 0.5)
            )
        case .tablet:
            return DynamicLayoutConfig(
                cardSize: 1.2,
                padding: 20,
                cornerRadius: 12,
                fontSize: FontSizes(title: 24, body: 20, caption: 18, small: 16),
                radiusFactors: RadiusFactors(avatar: 0.95, hand: 0.75, meld: 0.55)
            )
        case .desktop:
            return DynamicLayoutConfig(
                cardSize: 1.4,
                padding: 24,
                cornerRadius: 14,
                fontSize: FontSizes(title: 28, body: 24, caption: 20, small: 18),
                radiusFactors: RadiusFactors(avatar: 1.0, hand: 0.8, meld: 0.6)
            )
        }
    }
}

// MARK: - Adaptive Floating Button Style
struct AdaptiveFloatingButtonStyle: ButtonStyle {
    let config: DynamicLayoutConfig
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: config.fontSize.body))
            .foregroundColor(.white)
            .frame(width: 44 * config.cardSize, height: 44 * config.cardSize)
            .background(
                Circle()
                    .fill(GameBoardConstants.Colors.primaryGreen)
                    .shadow(radius: 4, x: 2, y: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Responsive Content Extension
extension GameBoardView {
    @ViewBuilder
    func responsiveContent(geometry: GeometryProxy) -> some View {
        let screenCategory = ScreenSizeCategory.categorize(
            width: geometry.size.width, 
            height: geometry.size.height
        )
        let config = DynamicLayoutConfig.config(for: screenCategory, geometry: geometry)
        
        // Choose layout based on device and orientation
        if UIDevice.current.userInterfaceIdiom == .phone {
            if geometry.size.width > geometry.size.height {
                phoneLandscapeLayout(geometry: geometry, screenCategory: screenCategory, config: config)
            } else {
                phonePortraitLayout(geometry: geometry, screenCategory: screenCategory, config: config)
            }
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            tabletLayout(geometry: geometry, screenCategory: screenCategory, config: config)
        } else {
            desktopLayout(geometry: geometry, screenCategory: screenCategory, config: config)
        }
    }
    
    // MARK: - Phone Portrait Layout
    private func phonePortraitLayout(geometry: GeometryProxy, screenCategory: ScreenSizeCategory, config: DynamicLayoutConfig) -> some View {
        return VStack(spacing: 0) {
            // Top: Compact info
            if screenCategory != .compact {
                HStack {
                    ForEach(game.players) { player in
                        VStack {
                            Text(player.name)
                                .font(.system(size: config.fontSize.caption))
                            Text("\(player.totalPoints)")
                                .font(.system(size: config.fontSize.caption, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(config.padding * 0.5)
            }
            
            // Center: Simplified game area
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(GameBoardConstants.Colors.tableGreen)
                    .padding(config.padding)
                
                // Just the trick area for now
                TrickView(
                    cards: game.currentTrick,
                    game: game,
                    settings: settings,
                    gameRules: gameRules
                )
                .frame(
                    width: geometry.size.width * 0.6 * config.cardSize,
                    height: geometry.size.height * 0.3 * config.cardSize
                )
            }
            
            Spacer()
            
            // Bottom: Current player's hand
            if let currentPlayer = game.players.first(where: { $0.isCurrentPlayer }) {
                HandView(
                    cards: currentPlayer.held,
                    playableCards: game.getPlayableCards(),
                    selectedCards: viewState.selectedCards,
                    onCardTap: { card in handleCardTap(card) },
                    onDoubleTap: { card in handleCardDoubleTap(card) }
                )
                .scaleEffect(config.cardSize)
                .padding(.bottom, config.padding)
            }
        }
        .overlay(
            // Simple floating button
            HStack {
                Spacer()
                VStack {
                    Button(action: handleShowSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: config.fontSize.body))
                    }
                    .buttonStyle(AdaptiveFloatingButtonStyle(config: config))
                    Spacer()
                }
            }
            .padding(config.padding)
        )
    }
    
    // MARK: - Phone Landscape Layout
    private func phoneLandscapeLayout(geometry: GeometryProxy, screenCategory: ScreenSizeCategory, config: DynamicLayoutConfig) -> some View {
        HStack(spacing: 0) {
            // Left: Player info
            VStack {
                ForEach(game.players) { player in
                    VStack {
                        Text(player.name)
                            .font(.system(size: config.fontSize.small))
                        Text("\(player.totalPoints)")
                            .font(.system(size: config.fontSize.small, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .padding(config.padding * 0.3)
                }
                Spacer()
            }
            .frame(width: geometry.size.width * 0.2)
            
            // Center: Game area
            ZStack {
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(GameBoardConstants.Colors.tableGreen)
                    .padding(config.padding)
                
                TrickView(
                    cards: game.currentTrick,
                    game: game,
                    settings: settings,
                    gameRules: gameRules
                )
                .frame(
                    width: geometry.size.width * 0.4 * config.cardSize,
                    height: geometry.size.height * 0.5 * config.cardSize
                )
            }
            
            // Right: Current player's hand
            if let currentPlayer = game.players.first(where: { $0.isCurrentPlayer }) {
                VStack {
                    Spacer()
                    HandView(
                        cards: currentPlayer.held,
                        playableCards: game.getPlayableCards(),
                        selectedCards: viewState.selectedCards,
                        onCardTap: { card in handleCardTap(card) },
                        onDoubleTap: { card in handleCardDoubleTap(card) }
                    )
                    .scaleEffect(config.cardSize)
                    .padding(.trailing, config.padding)
                }
                .frame(width: geometry.size.width * 0.4)
            }
        }
        .overlay(
            // Settings button
            VStack {
                Button(action: handleShowSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: config.fontSize.body))
                }
                .buttonStyle(AdaptiveFloatingButtonStyle(config: config))
                Spacer()
            }
            .padding(config.padding),
            alignment: .topTrailing
        )
    }
    
    // MARK: - Tablet Layout
    private func tabletLayout(geometry: GeometryProxy, screenCategory: ScreenSizeCategory, config: DynamicLayoutConfig) -> some View {
        // For now, use the existing layout but scaled
        return scaledExistingLayout(geometry: geometry, config: config)
    }
    
    // MARK: - Desktop Layout
    private func desktopLayout(geometry: GeometryProxy, screenCategory: ScreenSizeCategory, config: DynamicLayoutConfig) -> some View {
        // For now, use the existing layout but scaled
        return scaledExistingLayout(geometry: geometry, config: config)
    }
    
    // MARK: - Scaled Existing Layout (Phase 1)
    private func scaledExistingLayout(geometry: GeometryProxy, config: DynamicLayoutConfig) -> some View {
        return VStack(spacing: 0) {
            // Your existing scoreboard, but scaled
            GameScoreboardView(game: game, settings: settings)
                .scaleEffect(config.cardSize)
            
            // Your existing main area, but with adaptive padding
            ZStack {
                RoundedRectangle(cornerRadius: GameBoardConstants.extraLargeCornerRadius * config.cardSize)
                    .fill(GameBoardConstants.Colors.tableGreen)
                    .stroke(GameBoardConstants.Colors.primaryGreen, lineWidth: GameBoardConstants.strokeWidth)
                    .padding(40 * config.cardSize) // Scale the padding
                
                // Your existing concentric squares, but pass config for scaling
                concentricSquaresContent(playerCount: game.players.count, geometry: geometry, config: config)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Your existing overlay, but with scaled buttons
        .overlay(
            adaptiveFloatingButtons(config: config),
            alignment: .topTrailing
        )
    }
    
    // MARK: - Adaptive Floating Buttons
    private func adaptiveFloatingButtons(config: DynamicLayoutConfig) -> some View {
        HStack(spacing: GameBoardConstants.buttonSpacing * config.cardSize) {
            // End Game button or Start New Game (setup phase)
            if game.currentPhase == .setup {
                Button(action: handleStartNewGame) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: config.fontSize.body))
                }
                .buttonStyle(AdaptiveFloatingButtonStyle(config: config))
            } else {
                Button(action: handleEndGame) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: config.fontSize.body))
                }
                .buttonStyle(AdaptiveFloatingButtonStyle(config: config))
            }
            
            // Settings button
            Button(action: handleShowSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: config.fontSize.body))
            }
            .buttonStyle(AdaptiveFloatingButtonStyle(config: config))
            
            // Save Game button - only show when not in setup
            if game.currentPhase != .setup {
                Button(action: handleSaveGame) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: config.fontSize.body))
                }
                .buttonStyle(AdaptiveFloatingButtonStyle(config: config))
            }
        }
        .padding(.trailing, GameBoardConstants.buttonPadding * config.cardSize)
        .padding(.top, GameBoardConstants.topButtonPadding * config.cardSize)
    }
} 