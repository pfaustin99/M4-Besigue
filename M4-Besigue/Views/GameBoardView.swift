import SwiftUI

struct GameBoardView: View {
    @ObservedObject var game: Game
    @ObservedObject var settings: GameSettings
    @State private var selectedCards: [PlayerCard] = []
    @State private var showingMeldOptions = false
    @State private var showingSettings = false
    @State private var showingBadgeLegend = false
    @State private var showInvalidMeld: Bool = false
    @State private var shakeMeldButton: Bool = false
    @Namespace private var drawPileNamespace
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topSection
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
                centerSection
                    .frame(height: geometry.size.height * 0.4)
                bottomSection
                    .frame(height: geometry.size.height * 0.3)
            }
        }
        .background(Color.green.opacity(0.3))
        .sheet(isPresented: $showingMeldOptions) {
            MeldOptionsView(game: game, settings: settings, selectedCards: $selectedCards)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: settings)
        }
        .sheet(isPresented: $showingBadgeLegend) {
            BadgeLegendView(settings: settings)
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
                ForEach(0..<min(player.hand.count, 3), id: \.self) { _ in
                    CardBackView {
                        // No action
                    }
                    .frame(width: 24, height: 36)
                }
                if player.hand.count > 3 {
                    Text("+")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            // Meld area for each player
            if !player.meldsDeclared.isEmpty {
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
                ForEach(player.meldsDeclared) { meld in
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            ForEach(meld.cards) { card in
                                ZStack(alignment: .topTrailing) {
                                    Image(card.imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 30)
                                        .cornerRadius(3)
                                    HStack(spacing: 1) {
                                        if card.usedInMeldTypes.count == MeldType.allCases.count {
                                            Text("⚠️")
                                                .font(.system(size: 10))
                                                .padding(1)
                                        } else {
                                            ForEach(Array(card.usedInMeldTypes), id: \.self) { meldType in
                                                Text(badgeIcon(for: meldType, card: card))
                                                    .font(.system(size: 10))
                                                    .padding(1)
                                            }
                                        }
                                    }
                                    .background(Color.white.opacity(0.7))
                                    .clipShape(Capsule())
                                    .offset(x: 2, y: -2)
                                }
                            }
                        }
                        Text(meld.type.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("+\(meld.pointValue)")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    .padding(2)
                    .background(Color.yellow.opacity(0.12))
                    .cornerRadius(4)
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    // MARK: - Center Section
    private var centerSection: some View {
        VStack(spacing: 15) {
            // Dealer determination view
            if game.currentPhase == .dealerDetermination {
                dealerDeterminationView
            } else {
                // Main game area with trick and draw pile
                HStack(spacing: 20) {
                    // Draw pile positioned based on settings
                    if settings.drawPilePosition == .centerLeft {
                        drawPileSection
                        Spacer()
                        trickSection
                    } else {
                        trickSection
                        Spacer()
                        drawPileSection
                    }
                }
                .padding(.horizontal)
                
                // Jack drawn message
                if let jackCard = game.jackDrawnForDealer, game.showJackProminently {
                    jackDrawnMessage(PlayerCard(card: jackCard))
                }
                
                // Game controls (only for setup and dealer determination)
                if game.currentPhase == .setup || game.currentPhase == .dealerDetermination {
                    gameControls
                }
                
                // Error messages
                if showInvalidMeld {
                    Text("Invalid meld!")
                        .foregroundColor(.red)
                        .transition(.opacity)
                        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showInvalidMeld = false } }
                }
                
                // Show trick winner message using game state
                if game.isShowingTrickResult, let winner = game.lastTrickWinner {
                    Text("\(winner) won the trick!")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.purple)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .shadow(radius: 4)
                        .transition(.scale)
                }
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
                settings: settings
            )
            
            // Human draw button - below trick area
            if game.currentPlayer.type == .human && game.mustDrawCard && !game.awaitingMeldChoice {
                Button("Draw Card") {
                    withAnimation {
                        game.drawCardForCurrentPlayer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Draw Pile Section
    private var drawPileSection: some View {
        VStack(spacing: 8) {
            // Draw pile with stacking effect
            drawPileView
            
            // Deck info
            Text("Cards: \(game.deck.remainingCount)")
                .font(.caption)
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
            if let humanPlayer = game.players.first {
                playerInfoView(humanPlayer)
                if game.canPlayerMeld && game.currentPlayer.type == .human {
                    meldInstructionsView(humanPlayer)
                }
                if !humanPlayer.meldsDeclared.isEmpty {
                    meldsAreaView(humanPlayer)
                }
                actionButtonsView(humanPlayer)
                handView(humanPlayer)
            }
        }
    }
    
    private func playerInfoView(_ player: Player) -> some View {
        HStack {
            Text("Your Hand (\(player.hand.count) cards)")
                .font(.headline)
            Spacer()
            Text("Score: \(player.totalPoints)")
                .font(.headline)
        }
        .padding(.horizontal)
        .background(game.currentPlayer.id == player.id ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(8)
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
                let possibleMelds = game.getPossibleMelds(for: player).filter { meld in
                    meld.cards.count == selectedCards.count && meld.cards.allSatisfy { selectedCards.contains($0) }
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
        VStack(alignment: .leading, spacing: 4) {
            Text("Your Melds")
                .font(.subheadline)
                .bold()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(player.meldsDeclared) { meld in
                        VStack(spacing: 2) {
                            HStack(spacing: 2) {
                                ForEach(meld.cards) { card in
                                    Image(card.imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 48)
                                        .cornerRadius(4)
                                }
                            }
                            Text(meld.type.name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("+\(meld.pointValue)")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        .padding(4)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal)
    }
    
    private func actionButtonsView(_ player: Player) -> some View {
        HStack(spacing: 15) {
            // Declare Meld button: only during meld choice
            if game.awaitingMeldChoice && game.currentPlayer.type == .human {
                Button(action: {
                    if let humanPlayer = game.players.first, selectedCards.count >= 2, selectedCards.count <= 4 {
                        let meld = Meld(cards: selectedCards, type: .besigue, pointValue: settings.besiguePoints, roundNumber: game.roundNumber)
                        if game.canDeclareMeld(meld, by: humanPlayer) {
                            game.declareMeld(meld, by: humanPlayer)
                            selectedCards.removeAll()
                        } else {
                            withAnimation(.default) {
                                shakeMeldButton.toggle()
                                showInvalidMeld = true
                            }
                            game.playInvalidMeldAnimation()
                        }
                    } else {
                        withAnimation(.default) {
                            shakeMeldButton.toggle()
                            showInvalidMeld = true
                        }
                        game.playInvalidMeldAnimation()
                    }
                }) {
                    Text("Declare Meld")
                }
                .buttonStyle(.borderedProminent)
                .modifier(Shake(animatableData: CGFloat(shakeMeldButton ? 1 : 0)))
                .disabled(selectedCards.count < 2 || selectedCards.count > 4)
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
            
            if game.currentPhase == .dealerDetermination && game.currentPlayer.type == .human {
                Button("Draw Card for Dealer") {
                    game.drawCardForDealerDetermination()
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
        if game.currentPhase == .playing && game.currentPlayer.type == .human && !game.awaitingMeldChoice {
            // In playing phase, single tap selects card, double tap plays it
            if selectedCards.contains(card) {
                selectedCards.removeAll { $0 == card }
            } else {
                selectedCards = [card]
            }
        } else if game.awaitingMeldChoice && game.currentPlayer.type == .human {
            // In melding phase, tap to select/deselect cards for melds
            if selectedCards.contains(card) {
                selectedCards.removeAll { $0 == card }
            } else {
                selectedCards.append(card)
            }
        }
    }
    
    // Handle double-tap to play card
    private func handleCardDoubleTap(_ card: PlayerCard) {
        if game.canPlayCard() && game.currentPlayer.type == .human {
            // Double-tap plays the card immediately
            if let humanPlayer = game.players.first {
                game.playCard(card, from: humanPlayer)
                selectedCards.removeAll()
            }
        }
    }
    
    // Helper function for badge icon
    private func badgeIcon(for meldType: MeldType, card: PlayerCard) -> String {
        switch meldType {
        case .fourKings: return settings.badgeIcons.fourKings
        case .fourQueens: return settings.badgeIcons.fourQueens
        case .fourJacks: return settings.badgeIcons.fourJacks
        case .fourAces: return settings.badgeIcons.fourKings // You can add a unique icon for four aces if desired
        case .fourJokers: return settings.badgeIcons.fourJokers
        case .royalMarriage: return settings.badgeIcons.royalMarriage
        case .commonMarriage: return settings.badgeIcons.commonMarriage
        case .besigue: return settings.badgeIcons.besigue
        case .sequence: return "🛡️" // Superman badge placeholder
        }
    }
    
    // Dealer determination view
    private var dealerDeterminationView: some View {
        VStack(spacing: 15) {
            // Debug info
            if game.jackDrawnForDealer != nil {
                Text("DEBUG: Jack detected in UI!")
                    .font(.caption)
                    .foregroundColor(.red)
                    .bold()
            }
            
            // Debug: Show when showJackProminently is true
            if game.showJackProminently {
                Text("🎴 SHOW JACK PROMINENTLY FLAG IS TRUE! 🎴")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.red)
                    .background(Color.yellow)
                    .padding()
            }
            
            // TEST BUTTON: Force Jack to show for debugging
            Button("TEST: Force Show Jack") {
                if let jackCard = game.dealerDeterminationCards.first(where: { !$0.isJoker && $0.value == .jack }) {
                    game.jackDrawnForDealer = jackCard
                    game.showJackProminently = true
                    game.dealerDeterminedMessage = "TEST: Dealer is Player 1!"
                }
            }
            .buttonStyle(.borderedProminent)
            .background(Color.purple)
            .foregroundColor(.white)
            .padding()
            
            // Show the Jack that determined the dealer prominently (if drawn) - show during both phases
            if let jackCard = game.jackDrawnForDealer, game.showJackProminently {
                VStack(spacing: 12) {
                    Text("🎴 JACK DRAWN! 🎴")
                        .font(.title)
                        .bold()
                        .foregroundColor(.orange)
                    
                    Text(game.dealerDeterminedMessage)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                    
                    Image(jackCard.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 240) // 2x size (was 80x120)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange, lineWidth: 4)
                        )
                        .scaleEffect(1.05)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: jackCard.id)
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
                .scaleEffect(1.02)
                .animation(.easeInOut(duration: 0.3), value: jackCard.id)
            }
            
            // TEST: Show Jack prominently if we're in dealing phase and have cards
            if game.currentPhase == .dealing && !game.dealerDeterminationCards.isEmpty && !game.showJackProminently {
                // Find the Jack in the dealer determination cards
                if let jackCard = game.dealerDeterminationCards.first(where: { !$0.isJoker && $0.value == .jack }) {
                    VStack(spacing: 12) {
                        Text("🎴 JACK DRAWN! 🎴")
                            .font(.title)
                            .bold()
                            .foregroundColor(.orange)
                        
                        Text(game.dealerDeterminedMessage)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                        
                        Image(jackCard.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 160, height: 240) // 2x size
                            .cornerRadius(12)
                            .shadow(radius: 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange, lineWidth: 4)
                            )
                            .scaleEffect(1.05)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: jackCard.id)
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
                    .scaleEffect(1.02)
                    .animation(.easeInOut(duration: 0.3), value: jackCard.id)
                }
            }
            
            if game.currentPhase == .dealing {
                // Show dealer determined message and drawn cards
                VStack(spacing: 10) {
                    Text("🎉 Dealer Determined! 🎉")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                    
                    Text(game.dealerDeterminedMessage)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    // Show all drawn cards
                    if !game.dealerDeterminationCards.isEmpty {
                        VStack(spacing: 8) {
                            Text("All Cards Drawn:")
                                .font(.headline)
                            
                            // Single stack of cards with rotation and Z offset
                            ZStack {
                                ForEach(Array(game.dealerDeterminationCards.enumerated()), id: \.offset) { index, card in
                                    let rotation = Double((index * 13) % 21 - 10) // -10 to +10 degrees
                                    let zOffset = Double(index) * 2
                                    VStack(spacing: 4) {
                                        Image(card.imageName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 60, height: 90)
                                            .cornerRadius(6)
                                            .shadow(radius: 2)
                                            .rotationEffect(.degrees(rotation))
                                            .zIndex(Double(index))
                                            .offset(y: zOffset)
                                        if index < game.dealerDeterminationCards.count - 1 {
                                            Text("\(game.players[index % game.playerCount].name)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .offset(y: zOffset)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Text("Dealing cards...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
            } else {
                Text("Determining Dealer")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                
                Text("Players draw cards until someone draws a Jack")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Show drawn cards in a single stack
                if !game.dealerDeterminationCards.isEmpty {
                    VStack(spacing: 8) {
                        Text("Cards Drawn:")
                            .font(.headline)
                        
                        // Single stack of cards with rotation and Z offset
                        ZStack {
                            ForEach(Array(game.dealerDeterminationCards.enumerated()), id: \.offset) { index, card in
                                let rotation = Double((index * 13) % 21 - 10) // -10 to +10 degrees
                                let zOffset = Double(index) * 2
                                VStack(spacing: 4) {
                                    Image(card.imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 90)
                                        .cornerRadius(6)
                                        .shadow(radius: 2)
                                        .rotationEffect(.degrees(rotation))
                                        .zIndex(Double(index))
                                        .offset(y: zOffset)
                                    if index < game.dealerDeterminationCards.count - 1 {
                                        Text("\(game.players[index % game.playerCount].name)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .offset(y: zOffset)
                                    }
                                }
                            }
                        }
                        
                        // Show current player
                        if game.currentPlayer.type == .human {
                            Text("Your turn to draw")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .bold()
                        } else {
                            Text("\(game.currentPlayer.name) is drawing...")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Draw button for human player
                if game.currentPlayer.type == .human {
                    Button("Draw Card") {
                        game.drawCardForDealerDetermination()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Draw Pile View
    private var drawPileView: some View {
        let cardWidth: CGFloat = 80 * 1.5 // 1.5x size
        let cardHeight: CGFloat = 120 * 1.5
        let stackOffset: CGFloat = 3 // Offset for stacking effect
        let maxVisibleCards = min(4, game.deck.remainingCount) // Show 2-4 cards based on deck size
        
        return ZStack {
            // Stack of cards with offset and shadow
            ForEach(0..<maxVisibleCards, id: \.self) { index in
                Image("card_back")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: cardWidth, height: cardHeight)
                    .cornerRadius(8)
                    .offset(x: CGFloat(index) * stackOffset, y: CGFloat(index) * stackOffset)
                    .shadow(radius: 4, x: 2, y: 2)
                    .opacity(1.0 - Double(index) * 0.2) // Fade effect for depth
            }
        }
        .onTapGesture {
            if game.currentPlayer.type == .human && game.mustDrawCard && !game.awaitingMeldChoice {
                withAnimation(.easeInOut(duration: 0.3)) {
                    game.drawCardForCurrentPlayer()
                }
            }
        }
        .scaleEffect(game.currentPlayer.type == .human && game.mustDrawCard && !game.awaitingMeldChoice ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: game.mustDrawCard)
    }

    private func handView(_ player: Player) -> some View {
        let meldedCardIDs = Set(player.meldsDeclared.flatMap { $0.cards.map { $0.id } })
        let handCards = player.hand.filter { !meldedCardIDs.contains($0.id) }
        let possibleMeldCards: Set<UUID> = {
            if settings.gameLevel == .novice {
                let melds = game.getPossibleMelds(for: player)
                return Set(melds.flatMap { $0.cards.map { $0.id } })
            } else {
                return []
            }
        }()
        let playableCards: [PlayerCard]
        if game.awaitingMeldChoice {
            playableCards = handCards
        } else {
            playableCards = game.getPlayableCards()
        }
        return HandView(
            cards: handCards,
            playableCards: playableCards,
            selectedCards: selectedCards,
            showHintFor: possibleMeldCards
        ) { card in
            handleCardTap(card)
        } onDoubleTap: { card in
            handleCardDoubleTap(card)
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
                ForEach(0..<min(player.hand.count, 3), id: \.self) { _ in
                    CardBackView {
                        // No action for AI cards
                    }
                    .frame(width: 24, height: 36)
                }
                if player.hand.count > 3 {
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
                                let meldWithRound = Meld(cards: meld.cards, type: meld.type, pointValue: meld.pointValue, roundNumber: game.roundNumber)
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
                ForEach(meld.cards) { card in
                    Image(card.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 45)
                        .cornerRadius(4)
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
                    BadgeLegendRow(icon: settings.badgeIcons.fourKings, description: "Four Kings")
                    BadgeLegendRow(icon: settings.badgeIcons.fourQueens, description: "Four Queens")
                    BadgeLegendRow(icon: settings.badgeIcons.fourJacks, description: "Four Jacks")
                    BadgeLegendRow(icon: settings.badgeIcons.fourKings, description: "Four Aces") // You can add a unique icon for four aces if desired
                    BadgeLegendRow(icon: settings.badgeIcons.fourJokers, description: "Four Jokers")
                    BadgeLegendRow(icon: settings.badgeIcons.royalMarriage, description: "Royal Marriage")
                    BadgeLegendRow(icon: settings.badgeIcons.commonMarriage, description: "Common Marriage")
                    BadgeLegendRow(icon: settings.badgeIcons.besigue, description: "Bésigue")
                    BadgeLegendRow(icon: "🛡️", description: "Sequence (Trump Suit)")
                    BadgeLegendRow(icon: settings.badgeIcons.exhausted, description: "Meld-Exhausted")
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

struct TrickView: View {
    let cards: [PlayerCard]
    @ObservedObject var game: Game
    let settings: GameSettings
    
    var body: some View {
        ZStack {
            // Subtle background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            
            if cards.isEmpty {
                // Empty trick area
                Text("No cards played yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // Cards with natural rotation and z-depth
                HStack(spacing: 8) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        CardView(card: card, isSelected: false, onTap: {})
                            .frame(
                                width: 80 * settings.cardSizeMultiplier.rawValue,
                                height: 120 * settings.cardSizeMultiplier.rawValue
                            )
                            .rotationEffect(.degrees(Double.random(in: -5...5)))
                            .zIndex(Double(cards.count - index))
                            .shadow(radius: 2)
                    }
                }
            }
        }
        .frame(minHeight: 200)
        .padding(.horizontal)
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

#Preview {
    GameBoardView(game: Game(), settings: GameSettings(playerCount: 2))
} 