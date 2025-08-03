import SwiftUI

/// Displays the main game board with all players, cards, and interactions
/// - Parameters:
///   - game: The main game state object
///   - settings: User preferences and settings
///   - gameRules: Game rules and configuration
///   - onEndGame: Closure called when ending the game
struct GameBoardView: View {
    @ObservedObject var game: Game
    @ObservedObject var settings: GameSettings
    @ObservedObject var gameRules: GameRules
    let onEndGame: () -> Void
    
    // MARK: - State Management
    @StateObject var viewState = GameBoardViewState()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background for player areas
                Rectangle()
                    .fill(GameBoardConstants.Colors.backgroundGreen)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Elegant scoreboard
                    GameScoreboardView(game: game, settings: settings)
                    
                    // Main game table area
                    ZStack {
                        RoundedRectangle(cornerRadius: GameBoardConstants.extraLargeCornerRadius)
                            .fill(GameBoardConstants.Colors.tableGreen)
                            .stroke(GameBoardConstants.Colors.primaryGreen, lineWidth: GameBoardConstants.strokeWidth)
                            .padding(40)
                        
                        // Concentric squares content
                        concentricSquaresContent(playerCount: game.players.count, geometry: geometry)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Floating buttons overlay at top right
                .overlay(
                    HStack(spacing: GameBoardConstants.buttonSpacing) {
                        // End Game button or Start New Game (setup phase)
                        if game.currentPhase == .setup {
                            Button(action: handleStartNewGame) {
                                Image(systemName: "play.circle.fill")
                            }
                            .buttonStyle(FloatingButtonStyle())
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: GameBoardConstants.buttonAnimationDuration), value: true)
                        } else {
                            Button(action: handleEndGame) {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(FloatingButtonStyle())
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: GameBoardConstants.buttonAnimationDuration), value: true)
                        }
                        
                        // Settings button
                        Button(action: handleShowSettings) {
                            Image(systemName: "gearshape.fill")
                        }
                        .buttonStyle(FloatingButtonStyle())
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: GameBoardConstants.buttonAnimationDuration), value: true)
                        
                        // Save Game button - only show when not in setup
                        if game.currentPhase != .setup {
                            Button(action: handleSaveGame) {
                                Image(systemName: "square.and.arrow.down.fill")
                            }
                            .buttonStyle(FloatingButtonStyle())
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: GameBoardConstants.buttonAnimationDuration), value: true)
                        }
                    }
                    .padding(.trailing, GameBoardConstants.buttonPadding)
                    .padding(.top, GameBoardConstants.topButtonPadding),
                    alignment: .topTrailing
                )
            }
        }
        .onAppear {
            // GameBoardView appeared
        }
        .sheet(isPresented: $viewState.showingMeldOptions) {
            MeldOptionsView(game: self.game, settings: self.settings, selectedCards: $viewState.selectedCards)
        }
        .sheet(isPresented: $viewState.showingSettings) {
            SettingsView(settings: self.settings)
        }
        .sheet(isPresented: $viewState.showingBadgeLegend) {
            BadgeLegendView()
        }
    }
    

    
    // MARK: - Game Concentric Squares Content
    private func gameConcentricSquaresContent(geometry: GeometryProxy) -> some View {
        let center = getGameBoardCenter(geometry: geometry)
        return ZStack {
            ForEach(0..<self.game.players.count, id: \.self) { index in
                let pos = getPlayerPositions(index: index, playerCount: self.game.players.count, center: center, geometry: geometry)
                
                Group {
                    gamePlayerNameView(for: index, at: pos.avatarPosition)
                    gamePlayerHandView(for: index, at: pos.handPosition, isHorizontal: pos.isHorizontal, angle: pos.angle)
                    if index != 0 {
                        gamePlayerMeldView(for: index, at: pos.meldPosition, isHorizontal: pos.isHorizontal)
                    }
                }
            }
            
            // Trick area with actual cards
            gameTrickAreaView(at: center)
        }
    }
    
    // MARK: - Game Player Views (delegated to extension)
    // These methods are now implemented in GameBoardView+PlayerViews.swift
    // They use GameBoardConstants for consistent styling and viewState for state management
    
    private func gameTrickAreaView(at center: CGPoint) -> some View {
        let trickFrame = getTrickAreaFrame()
        
        return Group {
            if self.game.currentTrick.isEmpty {
                // Show placeholder like TestTableLayoutView
                VStack(spacing: 4) {
                    Text("TRICK AREA")
                        .font(.caption).bold()
                        .foregroundColor(GameBoardConstants.Colors.primaryGreen)
                    Text("Cards played here")
                        .font(.caption2)
                        .foregroundColor(GameBoardConstants.Colors.primaryGreen)
                }
                .frame(width: 100)
                .fixedSize()
            } else {
                // Show actual trick cards
                TrickView(
                    cards: self.game.currentTrick,
                    game: self.game,
                    settings: self.settings,
                    gameRules: self.gameRules
                )
                .frame(width: trickFrame.width, height: trickFrame.height)
            }
        }
        .position(x: center.x, y: center.y)
    }
    

    
    // MARK: - Player View Helpers (matching TestTableLayoutView exactly)
    private func playerNameView(for index: Int, at position: CGPoint) -> some View {
        let player = self.game.players[index]
        let isCurrentPlayer = index == self.game.currentPlayerIndex
        
        return VStack(spacing: 4) {
                                    HStack {
                Text(player.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isCurrentPlayer ? .white : .secondary)
                
                if isCurrentPlayer {
                    Image(systemName: "person.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                }
                
                if player.type == .ai {
                    Image(systemName: "cpu")
                        .foregroundColor(.blue)
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isCurrentPlayer ? Color.blue.opacity(0.3) : Color.black.opacity(0.2))
            .cornerRadius(8)
        }
        .position(position)
    }

    private func playerHandView(for index: Int, at position: CGPoint, isHorizontal: Bool, angle: Double) -> some View {
        let player = self.game.players[index]
        let isCurrentPlayer = index == self.game.currentPlayerIndex
        
        return Group {
            if isCurrentPlayer {
                // Current player: show face-up cards with full functionality
                HandView(
                    cards: player.held,
                    playableCards: player.held,
                    selectedCards: viewState.selectedCards,
                    onCardTap: { card in
                        handleCardSelection(card)
                    },
                    onDoubleTap: { card in
                        handleCardPlayed(card)
                    }
                )
                .frame(width: isHorizontal ? 600 : 160, height: isHorizontal ? 160 : 600)
            } else {
                // Other players: show card backs
                Group {
                    if isHorizontal {
                        HStack(spacing: -40) {
                            ForEach(Array(player.hand.enumerated()), id: \.element.id) { cardIndex, _ in
                                CardBackView { }
                                    .frame(width: 60, height: 84) // Scaled down for other players
                                    .rotationEffect(.degrees(180 + getCardRotation(for: angle))) // Face toward the player + angle rotation
                                    .offset(x: CGFloat(cardIndex) * 8) // Increased overlap like top player
                            }
                        }
                    } else {
                        VStack(spacing: -60) {
                            ForEach(Array(player.hand.enumerated()), id: \.element.id) { cardIndex, _ in
                                CardBackView { }
                                    .frame(width: 60, height: 84) // Scaled down for other players
                                    .rotationEffect(.degrees(180 + getCardRotation(for: angle))) // Face toward the player + angle rotation
                                    .offset(y: CGFloat(cardIndex) * 8) // Increased overlap like top player
                            }
                        }
                    }
                }
            }
        }
        .position(position)
    }

    private func playerMeldView(for index: Int, at position: CGPoint, isHorizontal: Bool) -> some View {
        let player = self.game.players[index]
        
        return Group {
            if isHorizontal {
                HStack(spacing: 4) {
                    ForEach(0..<min(3, player.melded.count), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange)
                            .frame(width: 25, height: 35)
                    }
                }
            } else {
                VStack(spacing: 4) {
                    ForEach(0..<min(3, player.melded.count), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange)
                            .frame(width: 25, height: 35)
                    }
                }
            }
        }
        .position(position)
    }
    

    
    // MARK: - Draw Pile View
    private func drawPileView(center: CGPoint, geometry: GeometryProxy) -> some View {
        let dealerIndex = self.game.players.firstIndex(where: { $0.isDealer }) ?? 0
        let drawPilePosition = getDrawPilePosition(playerCount: self.game.players.count, dealerIndex: dealerIndex, center: center, geometry: geometry)
        
        return VStack(spacing: 4) {
            // Draw pile cards
            ZStack {
                ForEach(0..<min(3, self.game.deck.cards.count), id: \.self) { index in
                    CardBackView { }
                        .frame(width: 40, height: 60)
                        .offset(x: CGFloat(index) * 2, y: CGFloat(index) * 2)
                }
            }
            
            // Draw pile count
            Text("\(self.game.deck.cards.count)")
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.6))
                .cornerRadius(4)
        }
        .position(drawPilePosition)
        .onTapGesture {
            handleDrawPileTap()
        }
    }
    
    // MARK: - Draw Pile Position Calculation
    private func getDrawPilePosition(playerCount: Int, dealerIndex: Int, center: CGPoint, geometry: GeometryProxy) -> CGPoint {
        let minSide = min(geometry.size.width, geometry.size.height)
        let radius = minSide * 0.15 // Smaller radius for draw pile
        
        switch playerCount {
        case 2:
            // Draw pile on left side (opposite to players)
            return CGPoint(x: center.x - radius, y: center.y)
        case 3:
            // Draw pile on the open side (left, since right has player)
            return CGPoint(x: center.x - radius, y: center.y)
        case 4:
            // Draw pile in one of the corners, avoiding player positions
            // Place it in top-left corner
            return CGPoint(x: center.x - radius * 0.7, y: center.y - radius * 0.7)
        default:
            return center
        }
    }
    
    // MARK: - Helper Methods
    private func handleDrawPileTap() {
        // Handle draw pile tap - this will be implemented based on game state
        print("Draw pile tapped")
    }
    

    
    // MARK: - Menu Area with Single Player Mode Badge
    private var menuAreaView: some View {
        HStack(spacing: 12) {
            Button("New Game") {
                // New game action
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(6)
            
            Button("Settings") {
                viewState.showSettings()
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(6)
            
            // Unrestricted Mode Toggle
            Button(self.game.isUnrestrictedMode ? "Disable Unrestricted" : "Enable Unrestricted") {
                if self.game.isUnrestrictedMode {
                    self.game.disableUnrestrictedMode()
                } else {
                    self.game.enableUnrestrictedMode()
                }
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(self.game.isUnrestrictedMode ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
            .cornerRadius(6)
            
            // Run Tests Button
            Button("Run Tests") {
                self.game.runAllTests()
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(6)
            
            // Single Player Mode Badge (stationary in menu)
            if viewState.isSinglePlayerMode {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.purple)
                        .font(.caption2)
                    Text("Single Player Mode")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.2))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                )
            }
            
            Spacer()
            
            Button("Badge Legend") {
                viewState.showBadgeLegend()
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(6)
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Other Player's Hand View
    private var otherPlayerHandView: some View {
        let _ = self.game.players[self.game.currentPlayerIndex]
        let otherPlayer = self.game.players[(self.game.currentPlayerIndex + 1) % 2]
        
        return VStack(spacing: 4) {
            Text(otherPlayer.name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Spacer()
                ForEach(otherPlayer.hand) { _ in
                    CardBackView { }
                        .frame(width: 35, height: 52)
                }
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    

    
    // MARK: - Global Messages Area (Dynamic Single Message)
    private var globalMessagesView: some View {
        Group {
            if self.game.isShowingTrickResult, let winnerName = self.game.lastTrickWinner {
                // Priority 1: Trick winner message (Green theme)
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(GameBoardConstants.Colors.primaryGreen)
                        .font(.title3)
                    Text("\(winnerName) wins the trick!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(GameBoardConstants.Colors.primaryGreen)
                }
                .padding(.horizontal, GameBoardConstants.horizontalPadding)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: GameBoardConstants.largeCornerRadius)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: GameBoardConstants.largeCornerRadius)
                                .stroke(GameBoardConstants.Colors.strokeGreen, lineWidth: GameBoardConstants.mediumStrokeWidth)
                        )
                )
            } else if self.game.currentPhase == .playing {
                // Priority 2: Current player turn message (Blue theme)
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("\(self.game.currentPlayer.name)'s Turn")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, GameBoardConstants.horizontalPadding)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: GameBoardConstants.largeCornerRadius)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: GameBoardConstants.largeCornerRadius)
                                .stroke(GameBoardConstants.Colors.strokeBlue, lineWidth: GameBoardConstants.mediumStrokeWidth)
                        )
                )
            } else {
                // Priority 3: Dealer message (Gold theme)
                if let dealer = self.game.players.first(where: { $0.isDealer }) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(GameBoardConstants.Colors.primaryGold)
                            .font(.title3)
                        Text("Dealer: \(dealer.name)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, GameBoardConstants.horizontalPadding)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: GameBoardConstants.largeCornerRadius)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: GameBoardConstants.largeCornerRadius)
                                    .stroke(GameBoardConstants.Colors.primaryGold.opacity(0.3), lineWidth: GameBoardConstants.mediumStrokeWidth)
                            )
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: GameBoardConstants.animationDuration), value: self.game.currentPhase)
        .animation(.easeInOut(duration: GameBoardConstants.animationDuration), value: self.game.currentPlayerIndex)
        .animation(.easeInOut(duration: GameBoardConstants.animationDuration), value: self.game.isShowingTrickResult)
        .animation(.easeInOut(duration: GameBoardConstants.animationDuration), value: self.game.lastTrickWinner)
    }
    
    // MARK: - Player-Specific Messages Area
    private var playerSpecificMessagesView: some View {
        VStack(spacing: 2) {
            if self.game.currentPhase == .playing {
                let currentPlayer = self.game.currentPlayer
                
                // Draw card message - show when it's the player's turn to draw
                if self.game.mustDrawCard && currentPlayer.id == self.game.currentPlayer.id && !self.game.hasDrawnForNextTrick[currentPlayer.id, default: false] && !self.game.deck.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption2)
                        Text("Draw a card")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
                }
                
                // Play card message - show when player has drawn and can play
                if self.game.hasDrawnForNextTrick[currentPlayer.id, default: false] && self.game.canPlayCard() && currentPlayer.id == self.game.currentPlayer.id {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        Text("Play a card")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.8))
        .cornerRadius(6)
        .shadow(radius: 1)
    }
    
    // MARK: - Scoreboard
    private var scoreboardView: some View {
        HStack(spacing: 24) {
            Text("Player 1: \(self.game.players.first?.totalPoints ?? 0)")
                .font(.system(size: 32 * self.gameRules.scoreboardScale, weight: .bold, design: .rounded))
            Divider()
            Text("Player 2: \(self.game.players.last?.totalPoints ?? 0)")
                .font(.system(size: 32 * self.gameRules.scoreboardScale, weight: .bold, design: .rounded))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
        )
        .fixedSize()
    }
    

    
    // MARK: - Top Section
    private var topSection: some View {
        VStack(spacing: 10) {
            turnBannerView
            gameInfoView
            badgeLegendButton
            playersInfoView
        }
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Subviews for Top Section
    private var turnBannerView: some View {
        Group {
            if game.currentPhase == .playing || game.currentPhase == .endgame || game.currentPhase == .dealerDetermination {
                HStack {
                    Spacer()
                    Text("\(game.currentPlayer.name)'s Turn")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(20)
                        .shadow(radius: 2)
                    Spacer()
                }
            }
        }
    }
    
    private var gameInfoView: some View {
        VStack(spacing: 8) {
            // Main game info row
            HStack {
                Text("Round \(game.roundNumber)")
                    .font(.headline)
                Spacer()
                if let trump = game.trumpSuit {
                    Text("Trump: \(trump.displayName)")
                        .font(.headline)
                        .foregroundColor(.red)
                } else {
                    Text("Trump: None")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .italic()
                }
                Spacer()
                Text("Phase: \(phaseName)")
                    .font(.headline)
                    .foregroundColor(game.isEndgame ? .orange : .primary)
            }
            .padding(.horizontal)
            .background(game.isEndgame ? Color.orange.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
    }
    
    private var badgeLegendButton: some View {
        HStack {
            Spacer()
            Button(action: { viewState.showBadgeLegend() }) {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                    Text("Meld Badges")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
    
    private var playersInfoView: some View {
        HStack(alignment: .top, spacing: 20) {
            ForEach(game.players) { player in
                PlayerInfoCard(player: player, settings: settings)
            }
        }
    }
    
    // MARK: - Player Info Card
    private func PlayerInfoCard(player: Player, settings: GameSettings) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text(player.name)
                    .font(.headline)
                    .foregroundColor(player.isCurrentPlayer ? .blue : .primary)
                Text(": ")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(String(format: "%04d", player.totalPoints))
                    .font(.headline)
                    .foregroundColor(.green)
            }
            HStack(spacing: 2) {
                ForEach(0..<min(player.held.count, 3), id: \.self) { _ in
                    CardBackView {
                        // No action
                    }
                    .frame(width: 24, height: 36)
                }
                if player.held.count > 3 {
                    Text("+")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            // Meld area for each player
            if !player.melded.isEmpty {
                PlayerMeldsView(player: player, settings: settings)
            }
        }
        .padding(4)
        .background(player.isCurrentPlayer ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Player Melds View
    private func PlayerMeldsView(player: Player, settings: GameSettings) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Display unique melded cards instead of iterating over melds
                ForEach(player.getMeldedCardsInOrder()) { card in
                    VStack(spacing: 2) {
                        // Row 1: 4 badge cells in a 2x2 grid
                        VStack(spacing: 1) {
                            HStack(spacing: 1) {
                                // Top row: badges 1 and 2
                                ForEach(0..<2, id: \.self) { index in
                                    if index < card.usedInMeldTypes.count {
                                        let meldType = Array(card.usedInMeldTypes)[index]
                                        Text(badgeIcon(for: meldType, card: card))
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.black)
                                    } else {
                                        // Empty cell
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                            }
                            HStack(spacing: 1) {
                                // Bottom row: badges 3 and 4
                                ForEach(2..<4, id: \.self) { index in
                                    if index < card.usedInMeldTypes.count {
                                        let meldType = Array(card.usedInMeldTypes)[index]
                                        Text(badgeIcon(for: meldType, card: card))
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.black)
                                    } else {
                                        // Empty cell
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 0)
                        
                        // Row 2: The card
                        CardView(
                            card: card,
                            isSelected: viewState.selectedCards.contains(card),
                            isPlayable: true, // All melded cards are playable
                            showHint: false,
                            onTap: { handleCardTap(card) }
                        )
                        .frame(width: 80, height: 112)
                        .padding(12)
                        .opacity(1.0)
                        .onTapGesture(count: 2) {
                            handleCardDoubleTap(card)
                        }
                    }
                    .onDrag {
                        // Create drag item with card ID
                        NSItemProvider(object: card.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: MeldedCardDropDelegate(
                        card: card,
                        cards: player.getMeldedCardsInOrder(),
                        player: player
                    ))
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    // MARK: - Meld Card View
    private func MeldCardView(
        card: PlayerCard,
        settings: GameSettings,
        isPlayable: Bool,
        onTap: @escaping () -> Void,
        onDoubleTap: @escaping () -> Void
    ) -> some View {
        Image(card.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80 * settings.playerHandCardSize.rawValue, height: 120 * settings.playerHandCardSize.rawValue)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isPlayable ? Color.blue : Color.clear, lineWidth: isPlayable ? 2 : 0)
            )
            .scaleEffect(isPlayable ? 1.05 : 1.0)
            .opacity(isPlayable ? 1.0 : 0.7)
            .onTapGesture {
                onTap()
            }
            .onTapGesture(count: 2) {
                onDoubleTap()
            }
    }
    
    // MARK: - Center Section
    private var centerSection: some View {
        VStack(spacing: 0) {
            if game.players.count == 2 {
                twoPlayerCenterSection()
            } else {
                // 3/4 player layout: current player at bottom, others at top/left/right
                let currentPlayer = game.players[game.currentPlayerIndex]
                VStack(spacing: 0) {
                    // Top: all other players' hands (card backs)
                    HStack(spacing: 16) {
                        ForEach(game.players.indices.filter { $0 != game.currentPlayerIndex }, id: \.self) { idx in
                            VStack {
                                Text(game.players[idx].name)
                                    .font(.caption)
                                HStack {
                                    ForEach(game.players[idx].hand) { _ in
                                        CardBackView { }
                                            .frame(width: 32, height: 48)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                    // Bottom: current player's hand (face up, interactive)
                    playerMainArea(for: currentPlayer)
                }
            }
        }
        .overlay(
            // Card drawing animation overlay
            Group {
                if viewState.showDrawAnimation {
                    CardDrawAnimationView(
                        fromPosition: settings.drawPilePosition
                    )
                }
            }
        )
        .overlay(
            // AI card draw animation overlay
            Group {
                if game.isAIDrawingCard, let aiCard = game.aiDrawnCard {
                    AICardDrawAnimationView(
                        card: aiCard,
                        fromPosition: settings.drawPilePosition
                    )
                    .onAppear {
                        print("🎬 AICardDrawAnimationView appeared")
                    }
                }
            }
        )
    }
    
    // MARK: - 2-Player Center Section
    private func twoPlayerCenterSection() -> some View {
        let currentPlayer = game.players[game.currentPlayerIndex]
        let otherPlayer = game.players[(game.currentPlayerIndex + 1) % 2]
        return HStack(alignment: .center, spacing: 0) {
            // Top: other player's hand (card backs)
            HStack {
                ForEach(otherPlayer.held) { _ in
                    CardBackView { }
                        .frame(width: 36, height: 54)
                }
            }
            .padding(.top, 8)
            // Center: Trick area (the table)
            TrickView(
                cards: game.currentTrick,
                game: game,
                settings: settings,
                gameRules: gameRules
            )
            // Bottom: current player's hand (face up, interactive)
            let isCurrentPlayer = game.currentPlayerIndex == game.players.firstIndex(where: { $0.id == currentPlayer.id })
            let playableCards = isCurrentPlayer ? game.getPlayableCards() : []
            
            HandView(
                cards: currentPlayer.held,
                playableCards: playableCards,
                selectedCards: viewState.selectedCards,
                showHintFor: []
            ) { card in
                if isCurrentPlayer {
                    handleCardTap(card)
                }
            } onDoubleTap: { card in
                if isCurrentPlayer {
                    handleCardDoubleTap(card)
                }
            } onReorder: { newOrder in
                // Update the player's held cards order
                currentPlayer.held = newOrder
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Trick Section
    private var trickSection: some View {
        VStack {
            // Clean trick area - only cards, no text
            TrickView(
                cards: game.currentTrick,
                game: game,
                settings: settings,
                gameRules: gameRules
            )
        }
    }
    
    // MARK: - Draw Pile Section
    private var drawPileSection: some View {
        VStack(spacing: 4) {
            // Label for cards left, color changes when 4 or fewer rounds remain
            let cardsLeft = game.deck.remainingCount
            let playerCount = game.players.count
            let roundsLeft = playerCount > 0 ? cardsLeft / playerCount : 0
            Text("Cards left: \(cardsLeft)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(roundsLeft <= 4 ? .red : .primary)
            drawPileView
                .frame(width: 40 * gameRules.globalCardSize.rawValue, height: 60 * gameRules.globalCardSize.rawValue)
        }
    }
    
    // MARK: - Jack Drawn Message
    private func jackDrawnMessage(_ jackCard: PlayerCard) -> some View {
        VStack(spacing: 12) {
            Text("Jack of \(jackCard.suit?.rawValue.capitalized ?? "") drawn - \(game.dealerDeterminedMessage)")
                .font(.title3)
                .bold()
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
            
            Image(jackCard.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 180)
                .cornerRadius(12)
                .shadow(radius: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange, lineWidth: 4)
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange, lineWidth: 2)
                )
        )
    }
    
    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 10) {
            if game.players.count == 2 {
                // 2-player layout: current player at bottom, other at top
                let currentPlayer = game.players[game.currentPlayerIndex]
                let otherPlayer = game.players[(game.currentPlayerIndex + 1) % 2]
                VStack(spacing: 0) {
                    // Top: other player's hand (card backs)
                    HStack {
                        ForEach(otherPlayer.held) { _ in
                            CardBackView { }
                                .frame(width: 48, height: 72)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                    // Center: trick, melds, etc. (already handled in centerSection)
                    // Bottom: current player's hand (face up, interactive)
                    playerMainArea(for: currentPlayer)
                }
            } else {
                // 3/4 player layout: current player at bottom, others at top/left/right
                let currentPlayer = game.players[game.currentPlayerIndex]
                VStack(spacing: 0) {
                    // Top: all other players' hands (card backs)
                    HStack(spacing: 16) {
                        ForEach(game.players.indices.filter { $0 != game.currentPlayerIndex }, id: \.self) { idx in
                            VStack {
                                Text(game.players[idx].name)
                                    .font(.caption)
                                HStack {
                                    ForEach(game.players[idx].held) { _ in
                                        CardBackView { }
                                            .frame(width: 32, height: 48)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                    // Bottom: current player's hand (face up, interactive)
                    playerMainArea(for: currentPlayer)
                }
            }
        }
    }
    
    private func playerMainArea(for player: Player) -> some View {
        VStack(spacing: 0) {
            playerInfoView(player)
            let showMeldInstructions = game.canPlayerMeld && player.type == .human && player.id == game.trickWinnerId
            if showMeldInstructions {
                meldInstructionsView(player)
            }
            if !player.melded.isEmpty {
                meldedCardsAreaView(player)
            }
            actionButtonsView(player)
            handView(player)
        }
    }
    
    private func playerInfoView(_ player: Player) -> some View {
        VStack(spacing: 4) {
            // Player name and status row
            HStack {
                Text(player.name)
                    .font(.headline)
                    .foregroundColor(game.currentPlayer.id == player.id ? .blue : .primary)
                
                // Dealer indicator
                if player.isDealer {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                
                // Current player indicator
                if game.currentPlayer.id == player.id && game.currentPhase == .playing {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                
                Spacer()
                
                Text("Score: \(player.totalPoints)")
                    .font(.headline)
            }
            
            // Hand count (total = held + melded)
            let totalCards = player.hand.count
            Text("Hand: \(totalCards) cards (\(player.held.count) held, \(player.melded.count) melded)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(game.currentPlayer.id == player.id ? Color.blue.opacity(0.2) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(game.currentPlayer.id == player.id ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
    }
    
    private func meldInstructionsView(_ player: Player) -> some View {
        VStack(spacing: 4) {
            Text("Select 2-4 cards to declare a meld")
                .font(.subheadline)
                .foregroundColor(.blue)
                .bold()
            if !viewState.selectedCards.isEmpty {
                Text("Selected: \(viewState.selectedCards.count) cards")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if viewState.selectedCards.count >= 2 && viewState.selectedCards.count <= 4 {
                let selectedIDs = Set(viewState.selectedCards.map { $0.id })
                let possibleMelds = game.getPossibleMelds(for: player).filter { meld in
                    meld.cardIDs.count == viewState.selectedCards.count && Set(meld.cardIDs) == selectedIDs
                }
                if !possibleMelds.isEmpty {
                    Text("Possible melds:")
                        .font(.caption)
                        .foregroundColor(.green)
                    ForEach(possibleMelds) { meld in
                        Text("\(meld.type.name) (+\(meld.pointValue))")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("No valid meld with selected cards")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func meldsAreaView(_ player: Player) -> some View {
        // Get melded cards in user-defined order
        let meldedCards = player.getMeldedCardsInOrder()
        
        return VStack(alignment: .leading, spacing: 4) {
            Text("Your Melds")
                .font(.subheadline)
                .bold()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Display unique melded cards instead of iterating over melds
                    ForEach(meldedCards) { card in
                        VStack(spacing: 2) {
                            // Row 1: 4 badge cells in a 1x4 grid
                            VStack(spacing: 1) {
                                HStack(spacing: 1) {
                                    // Top row: badges 1 and 4
                                    ForEach(0..<4, id: \.self) { index in
                                        if index < card.usedInMeldTypes.count {
                                            let meldType = Array(card.usedInMeldTypes)[index]
                                            Text(badgeIcon(for: meldType, card: card))
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.black)
                                        } else {
                                            // Empty cell
                                            Circle()
                                                .fill(Color.clear)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                }
                                /* HStack(spacing: 1) {
                                    // Bottom row: badges 3 and 4
                                    ForEach(2..<4, id: \.self) { index in
                                        if index < card.usedInMeldTypes.count {
                                            let meldType = Array(card.usedInMeldTypes)[index]
                                            Text(badgeIcon(for: meldType, card: card))
                                                .font(.system(size: 12))
                                                .padding(2)
                                                .background(Color.white.opacity(0.8))
                                                .clipShape(Circle())
                                        } else {
                                            // Empty cell
                                            Circle()
                                                .fill(Color.clear)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                }  */
                            }
                            .padding(.bottom, 0)
                            
                            // Row 2: The card
                            CardView(
                                card: card,
                                isSelected: viewState.selectedCards.contains(card),
                                isPlayable: true, // All melded cards are playable
                                showHint: false,
                                onTap: { handleCardTap(card) }
                            )
                            .frame(width: 80, height: 112)
                            .padding(12)
                            .opacity(1.0)
                            .onTapGesture(count: 2) {
                                handleCardDoubleTap(card)
                            }
                        }
                        .onDrag {
                            // Create drag item with card ID
                            NSItemProvider(object: card.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: MeldedCardDropDelegate(
                            card: card,
                            cards: meldedCards,
                            player: player
                        ))
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal)
    }
    
    private func actionButtonsView(_ player: Player) -> some View {
        print("🔍 ACTION BUTTONS VIEW CALLED:")
        print("   Player: \(player.name)")
        print("   Player type: \(player.type)")
        print("   Current player: \(game.currentPlayer.name)")
        print("   Current player type: \(game.currentPlayer.type)")
        print("   Awaiting meld choice: \(game.awaitingMeldChoice)")
        print("   Can player meld: \(game.canPlayerMeld)")
        print("   Selected cards count: \(viewState.selectedCards.count)")
        
        return HStack(spacing: 15) {
            // Play Card button: when a card is selected and it's the player's turn to play
            if game.currentPhase == .playing && 
               game.currentPlayer.id == player.id && 
               !game.awaitingMeldChoice && 
               !viewState.selectedCards.isEmpty && 
               game.canPlayCard() {
                Button(action: {
                    if let cardToPlay = viewState.selectedCards.first {
                        game.playCard(cardToPlay, from: player)
                        viewState.selectedCards.removeAll()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                        Text("Play Card")
                    }
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
            }
            
            // Declare Meld button: only for trick winner during meld choice and 2-4 cards selected
            if game.awaitingMeldChoice && game.currentPlayer.type == .human && game.canPlayerMeld && viewState.selectedCards.count >= 2 && viewState.selectedCards.count <= 4 && player.id == game.trickWinnerId {
                Button(action: {
                    print("🔍 MELD BUTTON PRESSED:")
                    print("   Awaiting meld choice: \(game.awaitingMeldChoice)")
                    print("   Current player type: \(game.currentPlayer.type)")
                    print("   Selected cards count: \(viewState.selectedCards.count)")
                    print("   Selected cards: \(viewState.selectedCards.map { $0.displayName })")

                    let humanPlayer = game.currentPlayer
                    if humanPlayer.type == .human, viewState.selectedCards.count >= 2, viewState.selectedCards.count <= 4 {
                        // Deduplicate selected cards to prevent duplicates in meld
                        let uniqueSelectedCards = Array(Set(viewState.selectedCards))
                        print("   Original selected cards: \(viewState.selectedCards.count)")
                        print("   Unique selected cards: \(uniqueSelectedCards.count)")
                        
                        print("🔍 MELD CREATION DEBUG:")
                        print("   Selected cards: \(uniqueSelectedCards.map { "\($0.displayName) (ID: \($0.id))" })")
                        
                        // Log all possible melds for comparison
                        let possibleMelds = game.getPossibleMelds(for: humanPlayer)
                        print("🔍 ALL POSSIBLE MELDS FOR PLAYER:")
                        for meld in possibleMelds {
                            print("   \(meld.type.name): \(meld.cardIDs.compactMap { player.cardByID($0)?.displayName })")
                        }
                        
                        // Create a meld with the selected cards (they are already the correct instances)
                        if let meldType = game.getMeldTypeForCards(uniqueSelectedCards, trumpSuit: game.trumpSuit) {
                            let pointValue = game.getPointValueForMeldType(meldType)
                            let meld = Meld(cardIDs: uniqueSelectedCards.map { $0.id }, type: meldType, pointValue: pointValue, roundNumber: game.roundNumber)
                            
                            if game.canDeclareMeld(meld, by: humanPlayer) {
                                print("   Found meld: \(meld.type.name) with \(meld.cardIDs.count) cards")
                                game.declareMeld(meld, by: humanPlayer)
                                viewState.selectedCards.removeAll()
                            } else {
                                print("   ❌ Cannot declare meld")
                                withAnimation(.default) {
                                    viewState.shakeMeldButton.toggle()
                                    viewState.showInvalidMeld = true
                                }
                                game.playInvalidMeldAnimation()
                            }
                        } else {
                            print("   ❌ No valid meld found for selected cards")
                            withAnimation(.default) {
                                viewState.shakeMeldButton.toggle()
                                viewState.showInvalidMeld = true
                            }
                            game.playInvalidMeldAnimation()
                        }
                    } else {
                        print("   ❌ Invalid card selection")
                        withAnimation(.default) {
                            viewState.shakeMeldButton.toggle()
                            viewState.showInvalidMeld = true
                        }
                        game.playInvalidMeldAnimation()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                        Text("Declare Meld")
                    }
                }
                .buttonStyle(.borderedProminent)
                .modifier(Shake(animatableData: CGFloat(viewState.shakeMeldButton ? 1 : 0)))
                .font(.headline)
            }
            

        }
        .padding(.horizontal)
    }
    
    // MARK: - Floating Button Style
    struct FloatingButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color(hex: "#00209F"))
                .cornerRadius(25)
                .shadow(color: Color(hex: "#D21034"), radius: 3, x: 2, y: 2)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    // MARK: - Game Controls (Legacy - now replaced by floating buttons)
    private var gameControls: some View {
        HStack(spacing: 15) {
            if game.currentPhase == .setup {
                Button("Start New Game") {
                    game.startNewGame()
                }
                .buttonStyle(.borderedProminent)
                .foregroundColor(Color(hex: "#D21034"))
            } else {
                Button("End Game") {
                    onEndGame()
                }
                .buttonStyle(.bordered)
                .foregroundColor(Color(hex: "#D21034"))
                
                Button("Settings") {
                    viewState.showingSettings = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(Color(hex: "#D21034"))
                
                Button("Save Game") {
                    saveGame()
                }
                .buttonStyle(.bordered)
                .foregroundColor(Color(hex: "#D21034"))
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Save Game Function
    private func saveGame() {
        // TODO: Implement save game functionality
    }
    
    // MARK: - Computed Properties
    private var phaseName: String {
        switch game.currentPhase {
        case .setup: return "Setup"
        case .dealing: return "Dealing"
        case .playing: return "Playing"
        case .endgame: return "Endgame"
        case .scoring: return "Scoring"
        case .gameOver: return "Game Over"
        case .dealerDetermination: return "Dealer Determination"
        }
    }
    
    private var trickPlayerNames: [String] {
        guard !game.currentTrick.isEmpty else { return [] }
        
        var names: [String] = []
        for i in 0..<game.currentTrick.count {
            let playerIndex = (game.currentTrickLeader + i) % game.playerCount
            names.append(game.players[playerIndex].name)
        }
        return names
    }
    
    // Helper to check if the player has declared a meld this round
    private var hasDeclaredMeldThisRound: Bool {
        guard let humanPlayer = game.players.first else { return false }
        return humanPlayer.meldsDeclared.last?.roundNumber == game.roundNumber
    }

    // MARK: - Concentric Squares Content (Circular Layout)
    /// Displays all players centered around the trick area in a circular layout, aligned symmetrically.
    private func concentricSquaresContent(playerCount: Int, geometry: GeometryProxy) -> some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let minSide = min(geometry.size.width, geometry.size.height)

        let radiusFactors = (avatar: 0.85, hand: 0.65, meld: 0.45)
        let angles: [Double] = {
            switch playerCount {
            case 2: return [90, 270]
            case 3: return [90, 210, 330]
            case 4: return [90, 180, 270, 0]
            default: return []
            }
        }()

        return ZStack {
            ForEach(0..<playerCount, id: \.self) { index in
                let angle = angles[index]
                let rad = Angle(degrees: angle).radians
                let isHorizontal = angle == 90 || angle == 270

                let avatarPoint = {
                    let radius = minSide * radiusFactors.avatar / 2
                    let x = center.x + CGFloat(cos(rad)) * radius
                    let y = center.y + CGFloat(sin(rad)) * radius
                    return CGPoint(x: x, y: y)
                }()
                
                let handPoint = {
                    let radius = minSide * radiusFactors.hand / 2
                    let x = center.x + CGFloat(cos(rad)) * radius
                    let y = center.y + CGFloat(sin(rad)) * radius
                    return CGPoint(x: x, y: y)
                }()
                
                let meldPoint = {
                    let radius = minSide * radiusFactors.meld / 2
                    let x = center.x + CGFloat(cos(rad)) * radius
                    let y = center.y + CGFloat(sin(rad)) * radius
                    return CGPoint(x: x, y: y)
                }()

                Group {
                    gamePlayerNameView(for: index, at: avatarPoint)
                    gamePlayerHandView(for: index, at: handPoint, isHorizontal: isHorizontal, angle: angle)
                    if index != 0 {
                        gamePlayerMeldView(for: index, at: meldPoint, isHorizontal: isHorizontal)
                    }
                }
            }

            gameTrickAreaView(at: center)
        }
    }
    
    // MARK: - Actions
    private func handleCardTap(_ card: PlayerCard) {
        // Only allow card selection for melding when the current player is the trick winner
        if game.awaitingMeldChoice && game.currentPlayer.type == .human && game.canPlayerMeld && game.currentPlayer.id == game.trickWinnerId {
            print("🎯 CARD TAP:")
            print("   Card: \(card.displayName) (ID: \(card.id))")
            print("   Currently selected: \(viewState.selectedCards.map { "\($0.displayName) (ID: \($0.id))" })")
            print("   Card already in selectedCards: \(viewState.selectedCards.contains(card))")
            
            // In melding phase, tap to select/deselect cards for melds
            if viewState.selectedCards.contains(card) {
                viewState.selectedCards.removeAll { $0 == card }
                print("   ✅ Removed card from selection")
            } else if viewState.selectedCards.count < 4 {
                viewState.selectedCards.append(card)
                print("   ✅ Added card to selection")
            } else {
                print("   ❌ Cannot add more cards (already have 4)")
            }
            
            print("   Final selected cards: \(viewState.selectedCards.map { "\($0.displayName) (ID: \($0.id))" })")
        }
        // At all other times, do not allow card selection for melding or play
    }
    
    // Handle double-tap to play card
    private func handleCardDoubleTap(_ card: PlayerCard) {
        print("🎯 DOUBLE-TAP ATTEMPT:")
        print("   Card: \(card.displayName)")
        print("   Current player: \(game.currentPlayer.name)")
        print("   Can play card: \(game.canPlayCard())")
        print("   Current player type: \(game.currentPlayer.type)")
        print("   Is draw cycle: \(game.isDrawCycle)")
        print("   Has drawn: \(game.hasDrawnForNextTrick[game.currentPlayer.id, default: false])")
        print("   Current trick count: \(game.currentTrick.count)")
        print("   Player count: \(game.playerCount)")
        
        if game.canPlayCard() && game.currentPlayer.type == .human {
            print("✅ DOUBLE-TAP SUCCESS - Playing card")
            // Double-tap plays the card immediately using the current play cycle
            game.playCardForCurrentPlayTurn(card)
            viewState.selectedCards.removeAll()
        } else {
            print("❌ DOUBLE-TAP FAILED - Conditions not met")
        }
        if game.mustDrawCard { return }
    }
    
    // Helper function for badge icon
    func badgeIcon(for meldType: MeldType, card: PlayerCard) -> String {
        switch meldType {
        case .fourKings: return settings.badgeIcons.fourKingsIcon
        case .fourQueens: return settings.badgeIcons.fourQueensIcon
        case .fourJacks: return settings.badgeIcons.fourJacksIcon
        case .fourAces: return settings.badgeIcons.fourAcesIcon
        case .fourJokers: return settings.badgeIcons.fourJokersIcon
        case .royalMarriage: return settings.badgeIcons.royalMarriageIcon
        case .commonMarriage: return settings.badgeIcons.commonMarriageIcon
        case .besigue: return settings.badgeIcons.besigueIcon
        case .sequence: return settings.badgeIcons.sequenceIcon
        }
    }
    
    // MARK: - Draw Pile View
    private var drawPileView: some View {
        let cardWidth: CGFloat = 80 * 1.5 // 1.5x size
        let cardHeight: CGFloat = 120 * 1.5
        let stackOffset: CGFloat = 2 // Smaller offset for better stacking
        let maxVisibleCards = min(4, game.deck.remainingCount) // Show 2-4 cards based on deck size
        let canDraw = game.currentPhase == .playing && game.isDrawCycle && game.currentPlayer.type == .human && !game.hasDrawnForNextTrick[game.currentPlayer.id, default: false] && !game.deck.isEmpty
        return Button(action: {
            if canDraw {
                viewState.showDrawAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    game.drawCardForCurrentDrawTurn()
                    viewState.showDrawAnimation = false
                }
            }
        }) {
            ZStack {
                ForEach(0..<maxVisibleCards, id: \.self) { index in
                    Image("card_back")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: cardWidth, height: cardHeight)
                        .cornerRadius(8)
                        .offset(x: CGFloat(index) * stackOffset, y: CGFloat(index) * stackOffset)
                        .shadow(radius: 4, x: 2, y: 2)
                        .opacity(1.0 - Double(index) * 0.15)
                        .zIndex(Double(maxVisibleCards - index))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canDraw)
        .scaleEffect(canDraw ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: canDraw)
        .overlay(
            Group {
                if canDraw && !game.hasDrawnForNextTrick[game.currentPlayer.id, default: false] && !game.deck.isEmpty {
                    VStack {
                        Spacer()
                        Text("Tap to draw (your turn)")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                    .offset(y: cardHeight + 20)
                }
            }
        )
        .overlay(
            Group {
                if viewState.showDrawAnimation, let card = viewState.animatingDrawnCard {
                    DrawCardAnimationView(card: card)
                }
            }
        )
    }
    
    // Computed property to determine if player can draw
    private var canDrawCard: Bool {
        if game.currentPhase == .dealerDetermination {
            return game.currentPlayer.type == .human
        } else {
            return game.currentPlayer.type == .human && game.mustDrawCard && !game.awaitingMeldChoice
        }
    }
    
    // Computed property for draw instruction text
    private var drawInstructionText: String {
        if game.currentPhase == .dealerDetermination {
            return "Tap to draw for dealer"
        } else {
            return "Tap to draw"
        }
    }

    private func handView(_ player: Player) -> some View {
        // Use held cards directly (no more filtering needed)
        let heldCards = player.held
        let possibleMeldCards: Set<UUID> = {
            if settings.gameLevel == .novice {
                let melds = game.getPossibleMelds(for: player)
                return Set(melds.flatMap { $0.cardIDs })
            } else {
                return []
            }
        }()
        let canPlay = player.id == game.currentPlayer.id && game.hasDrawnForNextTrick[player.id, default: false] && !game.isDrawCycle
        let playableCards: [PlayerCard]
        if game.awaitingMeldChoice {
            playableCards = heldCards
        } else {
            playableCards = game.getPlayableCards()
        }
        return HandView(
            cards: heldCards,
            playableCards: canPlay ? playableCards : [],
            selectedCards: viewState.selectedCards,
            showHintFor: possibleMeldCards
        ) { card in
            if canPlay {
                handleCardTap(card)
            }
        } onDoubleTap: { card in
            if canPlay {
                handleCardDoubleTap(card)
            }
        } onReorder: { newOrder in
            // Update the player's held cards order
            player.updateHeldOrder(newOrder)
        }
    }

    // MARK: - Melded Cards Area (Unique Cards with All Badges)
    private func meldedCardsAreaView(_ player: Player) -> some View {
        let meldedCards = player.getMeldedCardsInOrder()
        return VStack(alignment: .leading, spacing: 4) {
            Text("Your Melded Cards")
                .font(.subheadline)
                .bold()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(meldedCards) { card in
                        MeldedCardWithBadgesView(
                            card: card,
                            isSelected: viewState.selectedCards.contains(card),
                            isPlayable: game.getPlayableCards().contains { $0.id == card.id },
                            onTap: { handleCardTap(card) },
                            onDoubleTap: { handleCardDoubleTap(card) },
                            settings: settings
                        )
                    }
                }
            }
        }
    }

    // MARK: - Melded Card With Badges View
    private struct MeldedCardWithBadgesView: View {
        let card: PlayerCard
        let isSelected: Bool
        let isPlayable: Bool
        let onTap: () -> Void
        let onDoubleTap: () -> Void
        let settings: GameSettings

        private func badgeIcon(for meldType: MeldType) -> String {
            switch meldType {
            case .fourKings: return settings.badgeIcons.fourKingsIcon
            case .fourQueens: return settings.badgeIcons.fourQueensIcon
            case .fourJacks: return settings.badgeIcons.fourJacksIcon
            case .fourAces: return settings.badgeIcons.fourAcesIcon
            case .fourJokers: return settings.badgeIcons.fourJokersIcon
            case .royalMarriage: return settings.badgeIcons.royalMarriageIcon
            case .commonMarriage: return settings.badgeIcons.commonMarriageIcon
            case .besigue: return settings.badgeIcons.besigueIcon
            case .sequence: return settings.badgeIcons.sequenceIcon
            }
        }

        var body: some View {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    ForEach(Array(card.usedInMeldTypes.prefix(4)), id: \.self) { meldType in
                        Text(badgeIcon(for: meldType))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                    }
                    ForEach(0..<(4 - card.usedInMeldTypes.count), id: \.self) { _ in
                        Spacer().frame(width: 22, height: 22)
                    }
                }
                CardView(
                    card: card,
                    isSelected: isSelected,
                    isPlayable: isPlayable,
                    showHint: false,
                    onTap: onTap
                )
                .frame(width: 80, height: 112)
                .padding(12)
                .opacity(1.0) // Always fully opaque for melded cards
                .onTapGesture {
                    onTap()
                }
                .onTapGesture(count: 2) {
                    onDoubleTap()
                }
            }
        }
    }
}

// MARK: - AI Player View
struct AIPlayerView: View {
    @ObservedObject var player: Player
    let isCurrentPlayer: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                Text(player.name)
                    .font(.headline)
                    .foregroundColor(isCurrentPlayer ? .blue : .primary)
                Text(": ")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(String(format: "%04d", player.totalPoints))
                    .font(.headline)
                    .foregroundColor(.green)
            }
            // Show card backs for AI players (smaller)
            HStack(spacing: 2) {
                ForEach(0..<min(player.held.count, 3), id: \.self) { _ in
                    CardBackView {
                        // No action for AI cards
                    }
                    .frame(width: 24, height: 36)
                }
                if player.held.count > 3 {
                    Text("+")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(4)
        .background(isCurrentPlayer ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Meld Options View
struct MeldOptionsView: View {
    @ObservedObject var game: Game
    @ObservedObject var settings: GameSettings
    @Binding var selectedCards: [PlayerCard]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let humanPlayer = game.players.first {
                    let possibleMelds = game.getPossibleMelds(for: humanPlayer).filter { game.canDeclareMeld($0, by: humanPlayer) }
                    if possibleMelds.isEmpty {
                        Text("No melds available")
                            .font(.headline)
                            .padding()
                    } else {
                        List(possibleMelds) { meld in
                            MeldRowView(meld: meld) {
                                // When a meld is declared, attach the round number
                                let meldWithRound = Meld(cardIDs: meld.cardIDs, type: meld.type, pointValue: meld.pointValue, roundNumber: game.roundNumber)
                                game.declareMeld(meldWithRound, by: humanPlayer)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Declare Melds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Meld Row View
struct MeldRowView: View {
    let meld: Meld
    let onDeclare: () -> Void
    @EnvironmentObject var game: Game
    @EnvironmentObject var settings: GameSettings
    @EnvironmentObject var player: Player
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(meld.type.name)
                    .font(.headline)
                
                Text("\(meld.pointValue) points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(meld.cardIDs, id: \.self) { cardID in
                    if let card = player.cardByID(cardID) {
                        Image(card.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 45)
                            .cornerRadius(4)
                    }
                }
            }
            
            Button("Declare") {
                onDeclare()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Badge Legend View
struct BadgeLegendView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: GameSettings
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Meld Badge Legend")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    BadgeLegendRow(icon: settings.badgeIcons.fourKingsIcon, description: "Four Kings")
                    BadgeLegendRow(icon: settings.badgeIcons.fourQueensIcon, description: "Four Queens")
                    BadgeLegendRow(icon: settings.badgeIcons.fourJacksIcon, description: "Four Jacks")
                    BadgeLegendRow(icon: settings.badgeIcons.fourAcesIcon, description: "Four Aces")
                    BadgeLegendRow(icon: settings.badgeIcons.fourJokersIcon, description: "Four Jokers")
                    BadgeLegendRow(icon: settings.badgeIcons.royalMarriageIcon, description: "Royal Marriage (Trump King+Queen)")
                    BadgeLegendRow(icon: settings.badgeIcons.commonMarriageIcon, description: "Marriage (King+Queen, non-trump)")
                    BadgeLegendRow(icon: settings.badgeIcons.besigueIcon, description: "Bésigue (Q♠+J♦)")
                    BadgeLegendRow(icon: settings.badgeIcons.sequenceIcon, description: "Sequence (Trump A-K-Q-J-10)")
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Badge Legend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Badge Legend Row
struct BadgeLegendRow: View {
    let icon: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 32, alignment: .center)
            Text(description)
                .font(.body)
            Spacer()
        }
    }
}

// MARK: - Animated Card View for Card Play Animation
struct AnimatedCardView: View {
    let card: PlayerCard
    let isAnimating: Bool
    @State private var animationProgress: CGFloat = 0
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var cardScale: CGFloat = 1.0
    @State private var cardZRotation: Double = 0
    
    var body: some View {
        Image(card.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80, height: 120)
            .cornerRadius(8)
            .shadow(radius: 4, x: 2, y: 2)
            .offset(cardOffset)
            .rotationEffect(.degrees(cardRotation))
            .rotation3DEffect(.degrees(cardZRotation), axis: (x: 0, y: 0, z: 1))
            .scaleEffect(cardScale)
            .onAppear {
                if isAnimating {
                    startAnimation()
                }
            }
            .onChange(of: isAnimating) { _, newValue in
                if newValue {
                    startAnimation()
                }
            }
    }
    
    private func startAnimation() {
        // Reset animation state
        animationProgress = 0
        cardOffset = CGSize(width: -200, height: -50) // Start from player's hand area
        cardRotation = -15 // Tilt backward
        cardScale = 1.0
        cardZRotation = 0
        
        // Animate card play
        withAnimation(.easeInOut(duration: 0.6)) {
            cardOffset = CGSize(width: 0, height: 0) // Move to center
            cardRotation = 0 // Flatten
            cardScale = 1.05 // Slight scale up
        }
        
        // Add spin animation
        withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
            cardZRotation = 360 // Full spin
        }
        
        // Bounce effect at the end
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                cardScale = 1.0
            }
        }
    }
}

// MARK: - Enhanced Draw Pile View (Perpendicular Ramp)
struct EnhancedDrawPileView: View {
    let cards: [Card] // Use the actual deck
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let showTapToDraw: Bool
    let onTap: () -> Void
    let numberOfPlayers: Int
    let longEdgeAngle: Double // θ, in degrees, defines the long edge orientation
    let rampLength: CGFloat // How far the ramp extends perpendicular to the long edge
    let rampStep: CGFloat? // Optional: override ramp step per card
    let zOffset: Double? // Optional: zIndex boost for top N cards
    
    private let maxStackDepth: Int = 16 // Max cards to show for performance
    
    var body: some View {
        // Calculate the perpendicular direction (θ+90°)
        let perpRadians = (longEdgeAngle + 90) * .pi / 180
        let perpDx = cos(perpRadians)
        let perpDy = sin(perpRadians)
        let stackDepth = min(cards.count, maxStackDepth)
        let topIndex = stackDepth - 1
        let rampStepValue = rampStep ?? (rampLength / CGFloat(max(1, stackDepth - 1)))
        
        ZStack(alignment: .leading) {
            ForEach(Array(cards.prefix(maxStackDepth).enumerated()), id: \.offset) { (index, card) in
                let offsetStep = topIndex - index
                let rampOffset = CGFloat(offsetStep) * rampStepValue
                let xOffset = rampOffset * perpDx
                let yOffset = rampOffset * perpDy
                let z: Double = (zOffset != nil && offsetStep < numberOfPlayers) ? 100 + Double(offsetStep) * (zOffset ?? 1) : Double(index)
                Image("card_back")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: cardWidth, height: cardHeight)
                    .offset(x: xOffset, y: yOffset)
                    .zIndex(z)
            }
        }
        .frame(width: cardWidth + abs(perpDx) * rampLength, height: cardHeight + abs(perpDy) * rampLength)
        .contentShape(Rectangle())
        .onTapGesture {
            if showTapToDraw {
                onTap()
            }
        }
    }
}

// MARK: - Enhanced Trick View with Animation Support
struct TrickView: View {
    let cards: [PlayerCard]
    @ObservedObject var game: Game
    let settings: GameSettings
    @ObservedObject var gameRules: GameRules

    // Use a single constant for card size
    private var cardWidth: CGFloat { 40 * gameRules.globalCardSize.rawValue }
    private var cardHeight: CGFloat { 60 * gameRules.globalCardSize.rawValue }

    var body: some View {
        ZStack {
            // Subtle background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)

            HStack(alignment: .center, spacing: 24) {
                if shouldShowDrawPileLeft {
                    VStack {
                        Spacer()
                        VStack(spacing: 4) {
                            let cardsLeft = game.deck.remainingCount
                            let playerCount = game.players.count
                            let roundsLeft = playerCount > 0 ? cardsLeft / playerCount : 0
                            Text("Cards left: \(cardsLeft)")
                              .font(.caption)
                              .fontWeight(.semibold)
                              .foregroundColor(roundsLeft <= 4 ? .red : .primary)
                            EnhancedDrawPileView(
                                cards: game.deck.cards,
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                showTapToDraw: shouldShowTapToDraw,
                                onTap: {
                                    if shouldShowTapToDraw {
                                        game.drawCardForCurrentDrawTurn()
                                    }
                                },
                                numberOfPlayers: game.players.count,
                                longEdgeAngle: 45,
                                rampLength: 0,
                                rampStep: nil,
                                zOffset: nil
                            )
                        }
                        .padding(.leading, 12) // Pad from left edge
                    }
                }
                Spacer(minLength: 0)
                ZStack {
                    if cards.isEmpty && game.dealerDeterminationCards.isEmpty {
                        Text("No cards played yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        if game.currentPhase == .dealerDetermination && !game.dealerDeterminationCards.isEmpty {
                            dealerDeterminationStack
                        }
                        if !cards.isEmpty {
                            gameplayStackView()
                        }
                    }
                }
                Spacer(minLength: 0)
                if shouldShowDrawPileRight {
                    VStack {
                        Spacer()
                        VStack(spacing: 4) {
                            let cardsLeft = game.deck.remainingCount
                            let playerCount = game.players.count
                            let roundsLeft = playerCount > 0 ? cardsLeft / playerCount : 0
                            Text("Cards left: \(cardsLeft)")
                              .font(.caption)
                              .fontWeight(.semibold)
                              .foregroundColor(roundsLeft <= 4 ? .red : .primary)
                            EnhancedDrawPileView(
                                cards: game.deck.cards,
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                showTapToDraw: shouldShowTapToDraw,
                                onTap: {
                                    if shouldShowTapToDraw {
                                        game.drawCardForCurrentDrawTurn()
                                    }
                                },
                                numberOfPlayers: game.players.count,
                                longEdgeAngle: 45,
                                rampLength: 0,
                                rampStep: nil,
                                zOffset: nil
                            )
                        }
                        .padding(.trailing, 12) // Pad from right edge
                    }
                }
            }
            // Animated card being played (if any)
            if game.isPlayingCard, let playedCard = game.playedCard {
                AnimatedCardView(card: playedCard, isAnimating: true)
                    .zIndex(1000) // Always on top during animation
            }
        }
        .frame(minHeight: getTrickAreaHeight())
        .padding(.horizontal)
    }

    // Helper: Should draw pile be on the left?
    private var shouldShowDrawPileLeft: Bool {
        guard let dealerIndex = game.players.firstIndex(where: { $0.isDealer }) else { return true }
        return dealerIndex == 0
    }
    // Helper: Should draw pile be on the right?
    private var shouldShowDrawPileRight: Bool {
        guard let dealerIndex = game.players.firstIndex(where: { $0.isDealer }) else { return false }
        return dealerIndex == 1
    }
    // Helper: Should show 'Tap to draw' message?
    private var shouldShowTapToDraw: Bool {
        game.mustDrawCard && game.currentPlayer.isCurrentPlayer && !game.hasDrawnForNextTrick[game.currentPlayer.id, default: false] && !game.deck.isEmpty
    }

    private func getTrickAreaHeight() -> CGFloat {
        switch settings.trickAreaSize {
        case .small:
            return 160
        case .medium:
            return 280
        case .large:
            return 400
        }
    }
    
    private var dealerDeterminationStack: some View {
        ForEach(Array(game.dealerDeterminationCards.enumerated().reversed()), id: \.offset) { index, card in
            let originalIndex = game.dealerDeterminationCards.count - 1 - index
            let zOffset = Double(originalIndex) * 3
            
            // Generate a random rotation based on the card's ID for consistency
            let seed = card.id.uuidString.hashValue
            let randomRotation = Double(seed % 360) - 180 // Range from -180 to 180 degrees
            let scaledRotation = randomRotation * 0.4 // Scale down for subtle rotation
            
            Image(card.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80 * gameRules.globalCardSize.rawValue, height: 120 * gameRules.globalCardSize.rawValue)
                .cornerRadius(8)
                .shadow(radius: 4)
                .rotationEffect(.degrees(scaledRotation))
                .offset(x: CGFloat(originalIndex) * 12, y: CGFloat(originalIndex) * 6 + CGFloat(zOffset))
                .zIndex(Double(index))
        }
    }
    
    @ViewBuilder
    private func gameplayStackView() -> some View {
        let displayTuples: [(Int, PlayerCard)] = (0..<cards.count).map { i in
            (cards.count - 1 - i, cards[i])
        }
        ForEach(displayTuples, id: \.0) { tuple in
            CardStackedView(card: tuple.1, displayIndex: tuple.0, settings: settings, gameRules: gameRules)
        }
    }
}

// Add Shake modifier for invalid meld feedback
struct Shake: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 10 * sin(animatableData * .pi * 4)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// Add DrawCardAnimationView below TrickView:
struct DrawCardAnimationView: View {
    let card: PlayerCard
    @State private var progress: CGFloat = 0
    @State private var flipped: Bool = false
    var body: some View {
        GeometryReader { geo in
            let start = CGPoint(x: geo.size.width * 0.15, y: geo.size.height * 0.8)
            let end = CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.3)
            Image(card.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80 * 2, height: 120 * 2)
                .rotation3DEffect(.degrees(flipped ? 0 : 90), axis: (x: 0, y: 1, z: 0))
                .position(x: start.x + (end.x - start.x) * progress, y: start.y + (end.y - start.y) * progress)
                .shadow(radius: 8)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.3)) { progress = 1 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.2)) { flipped = true }
                    }
                }
        }
    }
}

// MARK: - Card Draw Animation View
struct CardDrawAnimationView: View {
    let fromPosition: DrawPilePosition
    @State private var animationProgress: CGFloat = 0
    @State private var cardRotation: Double = 0
    @State private var cardScale: CGFloat = 1.0
    @State private var cardZRotation: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated card
                Image("card_back")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 120)
                    .cornerRadius(8)
                    .shadow(radius: 8, x: 4, y: 4)
                    .scaleEffect(cardScale)
                    .rotationEffect(.degrees(cardRotation))
                    .rotation3DEffect(.degrees(cardZRotation), axis: (x: 0, y: 1, z: 0))
                    .offset(
                        x: getCardOffsetX(geometry: geometry),
                        y: getCardOffsetY(geometry: geometry)
                    )
                    .opacity(1 - animationProgress)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func getCardOffsetX(geometry: GeometryProxy) -> CGFloat {
        let startX: CGFloat = fromPosition == .centerLeft ? -100 : 100
        let endX: CGFloat = 0
        return startX + (endX - startX) * animationProgress
    }
    
    private func getCardOffsetY(geometry: GeometryProxy) -> CGFloat {
        let startY: CGFloat = 0
        let endY: CGFloat = -50
        let arcHeight: CGFloat = -100
        let progress = animationProgress
        
        // Create an arc motion
        if progress <= 0.5 {
            // First half: go up
            return startY + (arcHeight - startY) * (progress * 2)
        } else {
            // Second half: come down
            let secondHalfProgress = (progress - 0.5) * 2
            return arcHeight + (endY - arcHeight) * secondHalfProgress
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 0.6)) {
            animationProgress = 1.0
            cardRotation = 360 // Full flip
            cardZRotation = 180 // 3D flip
            cardScale = 1.2 // Slight scale up during animation
        }
    }
}

// Add this subview above gameplayStackView:
struct CardStackedView: View {
    let card: PlayerCard
    let displayIndex: Int
    let settings: GameSettings
    @ObservedObject var gameRules: GameRules
    
    // Generate a random rotation based on the card's ID for consistency
    private var randomRotation: Double {
        let seed = card.id.uuidString.hashValue
        let random = Double(seed % 360) - 180 // Range from -180 to 180 degrees
        return random * 0.3 // Scale down for subtle rotation
    }
    
    var body: some View {
        Image(card.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80 * gameRules.globalCardSize.rawValue, height: 120 * gameRules.globalCardSize.rawValue)
            .cornerRadius(8)
            .shadow(radius: 4)
            .offset(x: CGFloat(displayIndex) * 12, y: CGFloat(displayIndex) * 6 + CGFloat(displayIndex) * 2)
            .rotationEffect(.degrees(randomRotation))
            .zIndex(Double(displayIndex))
    }
}

// Add this new view above the existing views:
struct TapToDrawMessage: View {
    @State private var isPulsing = false
    
    var body: some View {
        Text("Tap to Draw")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue)
                    .shadow(radius: 4)
            )
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - AI Card Draw Animation View
struct AICardDrawAnimationView: View {
    let card: PlayerCard
    let fromPosition: DrawPilePosition
    @State private var animationProgress: CGFloat = 0
    @State private var cardRotation: Double = 0
    @State private var cardScale: CGFloat = 1.0
    @State private var cardZRotation: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated card
                Image(card.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 120)
                    .cornerRadius(8)
                    .shadow(radius: 8, x: 4, y: 4)
                    .scaleEffect(cardScale)
                    .rotationEffect(.degrees(cardRotation))
                    .rotation3DEffect(.degrees(cardZRotation), axis: (x: 0, y: 1, z: 0))
                    .offset(
                        x: getCardOffsetX(geometry: geometry),
                        y: getCardOffsetY(geometry: geometry)
                    )
                    .opacity(1 - animationProgress)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func getCardOffsetX(geometry: GeometryProxy) -> CGFloat {
        let startX: CGFloat = fromPosition == .centerLeft ? -100 : 100
        let endX: CGFloat = fromPosition == .centerLeft ? -200 : 200 // Fly to AI player area
        return startX + (endX - startX) * animationProgress
    }
    
    private func getCardOffsetY(geometry: GeometryProxy) -> CGFloat {
        let startY: CGFloat = 0
        let endY: CGFloat = -150 // Fly up to AI player area
        let arcHeight: CGFloat = -200
        let progress = animationProgress
        
        // Create an arc motion
        if progress <= 0.5 {
            // First half: go up
            return startY + (arcHeight - startY) * (progress * 2)
        } else {
            // Second half: come down
            let secondHalfProgress = (progress - 0.5) * 2
            return arcHeight + (endY - arcHeight) * secondHalfProgress
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 0.6)) {
            animationProgress = 1.0
            cardRotation = 360 // Full flip
            cardZRotation = 180 // 3D flip
            cardScale = 1.2 // Slight scale up during animation
        }
    }
}

#if DEBUG
struct GameBoardView_Previews: PreviewProvider {
    static var previews: some View {
        GameBoardView(
            game: Game(gameRules: GameRules()), 
            settings: GameSettings(), 
            gameRules: GameRules(),
            onEndGame: {}
        )
    }
}
#endif

#Preview {
    GameBoardView(
        game: Game(gameRules: GameRules()), 
        settings: GameSettings(), 
        gameRules: GameRules(),
        onEndGame: {}
    )
} 

// MARK: - Melded Card Drop Delegate for Drag and Drop
struct MeldedCardDropDelegate: DropDelegate {
    let card: PlayerCard
    let cards: [PlayerCard]
    let player: Player
    
    func performDrop(info: DropInfo) -> Bool {
        // Get the dragged card ID
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        
        itemProvider.loadObject(ofClass: NSString.self) { string, _ in
            guard let cardIdString = string as? String,
                  let draggedCardId = UUID(uuidString: cardIdString),
                  let draggedCard = cards.first(where: { $0.id == draggedCardId }),
                  let draggedIndex = cards.firstIndex(where: { $0.id == draggedCardId }),
                  let dropIndex = cards.firstIndex(where: { $0.id == card.id }) else { return }
            
            DispatchQueue.main.async {
                // Create new order by moving the dragged card to the drop position
                var newOrder = cards
                newOrder.remove(at: draggedIndex)
                newOrder.insert(draggedCard, at: dropIndex)
                
                // Update the player's melded order
                let newMeldedOrder = newOrder.map { $0.id }
                player.updateMeldedOrder(newMeldedOrder)
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Visual feedback when dragging over a drop target
        // This could be enhanced with more visual cues
    }
    
    func dropExited(info: DropInfo) {
        // Clear visual feedback when leaving drop target
    }
}

// MARK: - Helper Functions
private func getCardRotation(for angle: Double) -> Double {
    // Determine proper card rotation based on player position
    switch angle {
    case 90:   // Bottom player
        return 0    // Cards horizontal and face up
    case 270:  // Top player  
        return 0    // Cards horizontal and face up
    case 180:  // Left player
        return 90   // Cards rotated 90° to stand vertically
    case 0:    // Right player (4 players)
        return 90   // Cards rotated 90° to stand vertically
    case 330:  // Right player (3 players)
        return 90   // Cards rotated 90° to stand vertically
    case 210:  // Left player (3 players)
        return 90   // Cards rotated 90° to stand vertically
    default:
        return 0    // Default to horizontal
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
