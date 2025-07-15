import SwiftUI

struct GameBoardView: View {
    @ObservedObject var game: Game
    @ObservedObject var settings: GameSettings
    @ObservedObject var gameRules: GameRules
    @State private var selectedCards: [PlayerCard] = []
    @State private var showingMeldOptions = false
    @State private var showingSettings = false
    @State private var showingBadgeLegend = false
    @State private var showInvalidMeld: Bool = false
    @State private var shakeMeldButton: Bool = false
    @Namespace private var drawPileNamespace
    @State private var animatingDrawnCard: PlayerCard? = nil
    @State private var showDrawAnimation: Bool = false
    @State private var isSinglePlayerMode: Bool = false
    @State private var tapCount: Int = 0
    @State private var lastTapTime: Date = Date()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Menu area with Single Player Mode badge
                menuAreaView
                    .padding(.horizontal)
                
                // Player Scores with triple tap detection
                scoreboardView
                    .onTapGesture(count: 1) {
                        handleScoreTap()
                    }
                    .padding(.bottom, 32) // Increased space between scores and game messages
                
                // Global Messages Area (Dynamic Single Message)
                globalMessagesView
                    .frame(height: 50)
                    .padding(.horizontal)
                    .padding(.bottom, 32) // Increased space between game messages and player's back card hands
                
                // Other Player's Hand (moved here)
                otherPlayerHandView
                    .frame(height: 80)
                    .padding(.horizontal)
                    .padding(.bottom, 36) // Increased space between other player's hand and trick area
                
                // Trick Area (increased height)
                TrickView(
                    cards: self.game.currentTrick,
                    game: self.game,
                    settings: self.settings,
                    gameRules: self.gameRules
                )
                .frame(height: geometry.size.height * (self.settings.trickAreaHeightPercentage / 100.0))
                .padding(.bottom, 8)
                
                // Player-Specific Messages Area
                playerSpecificMessagesView
                    .frame(height: 40)
                    .padding(.horizontal)
                
                // Main game content
                if self.game.players.count == 2 {
                    twoPlayerMainArea()
                } else {
                    // 3/4 player layout: current player at bottom, others at top/left/right
                    let currentPlayer = self.game.players[self.game.currentPlayerIndex]
                    VStack(spacing: 0) {
                        // Top: all other players' hands (card backs)
                        HStack(spacing: 16) {
                            ForEach(self.game.players.indices.filter { $0 != self.game.currentPlayerIndex }, id: \.self) { idx in
                                VStack {
                                    Text(self.game.players[idx].name)
                                        .font(.caption)
                                    HStack {
                                        ForEach(self.game.players[idx].hand) { _ in
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
        .background(Color.green.opacity(0.3))
        .onAppear {
            print("🎮 GameBoardView appeared - Players: \(self.game.players.count), Current: \(self.game.currentPlayerIndex)")
        }
        .sheet(isPresented: $showingMeldOptions) {
            MeldOptionsView(game: self.game, settings: self.settings, selectedCards: $selectedCards)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: self.settings)
        }
        .sheet(isPresented: $showingBadgeLegend) {
            BadgeLegendView(settings: self.settings)
        }
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
                showingSettings = true
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
            if isSinglePlayerMode {
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
                showingBadgeLegend = true
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
        let currentPlayer = self.game.players[self.game.currentPlayerIndex]
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
    
    // MARK: - Triple Tap Handler
    private func handleScoreTap() {
        let now = Date()
        if now.timeIntervalSince(lastTapTime) < 1.0 {
            tapCount += 1
            if tapCount >= 3 {
                isSinglePlayerMode.toggle()
                tapCount = 0
                print("🎮 Single Player Mode: \(isSinglePlayerMode ? "ON" : "OFF")")
            }
        } else {
            tapCount = 1
        }
        lastTapTime = now
    }
    
    // MARK: - Global Messages Area (Dynamic Single Message)
    private var globalMessagesView: some View {
        Group {
            if self.game.isShowingTrickResult, let winnerName = self.game.lastTrickWinner {
                // Priority 1: Trick winner message (Green theme)
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("\(winnerName) wins the trick!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 2)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        )
                )
            } else {
                // Priority 3: Dealer message (Gold theme)
                if let dealer = self.game.players.first(where: { $0.isDealer }) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                        Text("Dealer: \(dealer.name)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
                            )
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.3), value: self.game.currentPhase)
        .animation(.easeInOut(duration: 0.3), value: self.game.currentPlayerIndex)
        .animation(.easeInOut(duration: 0.3), value: self.game.isShowingTrickResult)
        .animation(.easeInOut(duration: 0.3), value: self.game.lastTrickWinner)
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
    
    // MARK: - 2-Player Main Area
    private func twoPlayerMainArea() -> some View {
        let currentPlayer = self.game.players[self.game.currentPlayerIndex]
        
        return VStack(spacing: 0) {
            if isSinglePlayerMode {
                // Single Player Mode: Active player's hand at bottom, rotated to your view
                singlePlayerLayout(currentPlayer: currentPlayer)
            } else {
                // Normal Mode: Current player at bottom
                normalTwoPlayerLayout(currentPlayer: currentPlayer)
            }
        }
        .onAppear {
            print("🎯 2-Player layout - Current: \(currentPlayer.name), Single Player: \(isSinglePlayerMode)")
        }
    }
    
    // MARK: - Single Player Layout (for testing)
    private func singlePlayerLayout(currentPlayer: Player) -> some View {
        VStack(spacing: 0) {
            // Player info and meld instructions
            playerInfoView(currentPlayer)
            if self.game.canPlayerMeld && currentPlayer.type == .human && currentPlayer.id == game.trickWinnerId {
                meldInstructionsView(currentPlayer)
            }
            if !currentPlayer.meldsDeclared.isEmpty {
                meldsAreaView(currentPlayer)
            }
            actionButtonsView(currentPlayer)
            
            // Active player's hand (face up, interactive) - rotated to your view
            VStack(spacing: 4) {
                Text("\(currentPlayer.name) (Your Turn)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                // Use HandView for drag-and-drop support
                HandView(
                    cards: currentPlayer.held,
                    playableCards: currentPlayer.held, // All cards playable in single player mode
                    selectedCards: self.selectedCards,
                    showHintFor: []
                ) { card in
                    handleCardTap(card)
                } onDoubleTap: { card in
                    handleCardDoubleTap(card)
                } onReorder: { newOrder in
                    // Update the player's held cards order
                    currentPlayer.held = newOrder
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .onChange(of: self.game.currentPlayerIndex) { newIndex in
            // In single player mode, automatically switch to the current player's hand
            // This ensures the trick winner's hand becomes active
            print("🎮 Single Player Mode: Switched to \(self.game.players[newIndex].name)'s hand")
        }
    }
    
    // MARK: - Normal Two Player Layout
    private func normalTwoPlayerLayout(currentPlayer: Player) -> some View {
        VStack(spacing: 0) {
            // Player info and meld instructions
            playerInfoView(currentPlayer)
            if self.game.canPlayerMeld && currentPlayer.type == .human && currentPlayer.id == game.trickWinnerId {
                meldInstructionsView(currentPlayer)
            }
            if !currentPlayer.melded.isEmpty {
                meldedCardsAreaView(currentPlayer)
            }
            actionButtonsView(currentPlayer)
            HandView(
                cards: currentPlayer.held,
                playableCards: game.getPlayableCards(),
                selectedCards: selectedCards,
                showHintFor: []
            ) { card in
                if game.currentPlayerIndex == game.players.firstIndex(where: { $0.id == currentPlayer.id }) {
                    handleCardTap(card)
                }
            } onDoubleTap: { card in
                if game.currentPlayerIndex == game.players.firstIndex(where: { $0.id == currentPlayer.id }) {
                    handleCardDoubleTap(card)
                }
            } onReorder: { newOrder in
                currentPlayer.held = newOrder
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
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
            Button(action: { showingBadgeLegend = true }) {
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
                            }
                            HStack(spacing: 1) {
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
                            }
                        }
                        .padding(.bottom, 0)
                        
                        // Row 2: The card
                        CardView(
                            card: card,
                            isSelected: selectedCards.contains(card),
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
                if showDrawAnimation {
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
            if settings.drawPilePosition == .centerLeft {
                drawPileSection
                Spacer(minLength: 16)
            }
            VStack(spacing: 0) {
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
                    selectedCards: selectedCards,
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
            if settings.drawPilePosition == .centerRight {
                Spacer(minLength: 16)
                drawPileSection
            }
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
            drawPileView
                                        .frame(width: 40 * gameRules.globalCardSize.rawValue, height: 60 * gameRules.globalCardSize.rawValue)
            Text("Cards: \(game.deck.remainingCount)")
                .font(.caption2)
                .foregroundColor(.secondary)
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
            if !selectedCards.isEmpty {
                Text("Selected: \(selectedCards.count) cards")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if selectedCards.count >= 2 && selectedCards.count <= 4 {
                let selectedIDs = Set(selectedCards.map { $0.id })
                let possibleMelds = game.getPossibleMelds(for: player).filter { meld in
                    meld.cardIDs.count == selectedCards.count && Set(meld.cardIDs) == selectedIDs
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
                                isSelected: selectedCards.contains(card),
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
        print("   Selected cards count: \(selectedCards.count)")
        
        return HStack(spacing: 15) {
            // Play Card button: when a card is selected and it's the player's turn to play
            if game.currentPhase == .playing && 
               game.currentPlayer.id == player.id && 
               !game.awaitingMeldChoice && 
               !selectedCards.isEmpty && 
               game.canPlayCard() {
                Button(action: {
                    if let cardToPlay = selectedCards.first {
                        game.playCard(cardToPlay, from: player)
                        selectedCards.removeAll()
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
            if game.awaitingMeldChoice && game.currentPlayer.type == .human && game.canPlayerMeld && selectedCards.count >= 2 && selectedCards.count <= 4 && player.id == game.trickWinnerId {
                Button(action: {
                    print("🔍 MELD BUTTON PRESSED:")
                    print("   Awaiting meld choice: \(game.awaitingMeldChoice)")
                    print("   Current player type: \(game.currentPlayer.type)")
                    print("   Selected cards count: \(selectedCards.count)")
                    print("   Selected cards: \(selectedCards.map { $0.displayName })")

                    let humanPlayer = game.currentPlayer
                    if humanPlayer.type == .human, selectedCards.count >= 2, selectedCards.count <= 4 {
                        // Deduplicate selected cards to prevent duplicates in meld
                        let uniqueSelectedCards = Array(Set(selectedCards))
                        print("   Original selected cards: \(selectedCards.count)")
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
                                selectedCards.removeAll()
                            } else {
                                print("   ❌ Cannot declare meld")
                                withAnimation(.default) {
                                    shakeMeldButton.toggle()
                                    showInvalidMeld = true
                                }
                                game.playInvalidMeldAnimation()
                            }
                        } else {
                            print("   ❌ No valid meld found for selected cards")
                            withAnimation(.default) {
                                shakeMeldButton.toggle()
                                showInvalidMeld = true
                            }
                            game.playInvalidMeldAnimation()
                        }
                    } else {
                        print("   ❌ Invalid card selection")
                        withAnimation(.default) {
                            shakeMeldButton.toggle()
                            showInvalidMeld = true
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
                .modifier(Shake(animatableData: CGFloat(shakeMeldButton ? 1 : 0)))
                .font(.headline)
            }
            

        }
        .padding(.horizontal)
    }
    
    // MARK: - Game Controls
    private var gameControls: some View {
        HStack(spacing: 15) {
            if game.currentPhase == .setup {
                Button("Start New Game") {
                    game.startNewGame()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
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
    
    // MARK: - Actions
    private func handleCardTap(_ card: PlayerCard) {
        // Only allow card selection for melding when the current player is the trick winner
        if game.awaitingMeldChoice && game.currentPlayer.type == .human && game.canPlayerMeld && game.currentPlayer.id == game.trickWinnerId {
            print("🎯 CARD TAP:")
            print("   Card: \(card.displayName) (ID: \(card.id))")
            print("   Currently selected: \(selectedCards.map { "\($0.displayName) (ID: \($0.id))" })")
            print("   Card already in selectedCards: \(selectedCards.contains(card))")
            
            // In melding phase, tap to select/deselect cards for melds
            if selectedCards.contains(card) {
                selectedCards.removeAll { $0 == card }
                print("   ✅ Removed card from selection")
            } else if selectedCards.count < 4 {
                selectedCards.append(card)
                print("   ✅ Added card to selection")
            } else {
                print("   ❌ Cannot add more cards (already have 4)")
            }
            
            print("   Final selected cards: \(selectedCards.map { "\($0.displayName) (ID: \($0.id))" })")
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
            selectedCards.removeAll()
        } else {
            print("❌ DOUBLE-TAP FAILED - Conditions not met")
        }
        if game.mustDrawCard { return }
    }
    
    // Helper function for badge icon
    private func badgeIcon(for meldType: MeldType, card: PlayerCard) -> String {
        switch meldType {
        case .fourKings: return settings.badgeIcons.fourKingsIcon
        case .fourQueens: return settings.badgeIcons.fourQueensIcon
        case .fourJacks: return settings.badgeIcons.fourJacksIcon
        case .fourAces: return settings.badgeIcons.fourAcesIcon
        case .fourJokers: return settings.badgeIcons.fourJokersIcon
        case .royalMarriage: return settings.badgeIcons.royalMarriageIcon
        case .commonMarriage: return settings.badgeIcons.commonMarriageIcon
        case .besigue: return settings.badgeIcons.besigueIcon
        case .sequence: return "🛡️" // Superman badge placeholder
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
                showDrawAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    game.drawCardForCurrentDrawTurn()
                    showDrawAnimation = false
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
                if showDrawAnimation, let card = animatingDrawnCard {
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
            selectedCards: selectedCards,
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
                            isSelected: selectedCards.contains(card),
                            isPlayable: game.getPlayableCards().contains { $0.id == card.id },
                            onTap: { handleCardTap(card) },
                            onDoubleTap: { handleCardDoubleTap(card) }
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

        private func badgeIcon(for meldType: MeldType) -> String {
            switch meldType {
            case .besigue: return "🂡🃏"
            case .royalMarriage: return "👑"
            case .commonMarriage: return "💍"
            case .fourJacks: return "🂫"
            case .fourQueens: return "🂭"
            case .fourKings: return "🂮"
            case .fourAces: return "🂡"
            case .fourJokers: return "🃏"
            case .sequence: return "➡️"
            }
        }

        var body: some View {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    ForEach(Array(card.usedInMeldTypes.prefix(4)), id: \.self) { meldType in
                        Text(badgeIcon(for: meldType))
                            .font(.system(size: 22))
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
    @ObservedObject var settings: GameSettings
    @Environment(\.dismiss) private var dismiss
    
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
                    BadgeLegendRow(icon: settings.badgeIcons.royalMarriageIcon, description: "Royal Marriage")
                    BadgeLegendRow(icon: settings.badgeIcons.commonMarriageIcon, description: "Common Marriage")
                    BadgeLegendRow(icon: settings.badgeIcons.besigueIcon, description: "Bésigue")
                    BadgeLegendRow(icon: "🛡️", description: "Sequence (Trump Suit)")
                    BadgeLegendRow(icon: "❌", description: "Meld-Exhausted")
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
                .font(.title2)
                .frame(width: 30, alignment: .center)
            
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

            HStack(alignment: .top, spacing: 24) {
                if shouldShowDrawPileLeft {
                    VStack(spacing: 6) {
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
                    VStack(spacing: 6) {
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
        GameBoardView(game: Game(gameRules: GameRules()), settings: GameSettings(), gameRules: GameRules())
    }
}
#endif

#Preview {
    GameBoardView(game: Game(gameRules: GameRules()), settings: GameSettings(), gameRules: GameRules())
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
