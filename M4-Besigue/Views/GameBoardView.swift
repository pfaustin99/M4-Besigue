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
            if game.currentPhase == .playing || game.currentPhase == .endgame {
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
                Text("Trump: \(trump.rawValue.capitalized)")
                    .font(.headline)
                    .foregroundColor(.red)
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
                // Current trick
                TrickView(
                    cards: game.currentTrick,
                    playerNames: trickPlayerNames,
                    winningIndex: game.isShowingTrickResult ? game.determineTrickWinnerIndex() : nil,
                    game: game
                )
                // Game controls
                gameControls
                // Deck info and draw pile
                HStack {
                    VStack(alignment: .leading) {
                        Text("Cards in deck: \(game.deck.remainingCount)")
                            .font(.caption)
                        drawPileView
                    }
                    Spacer()
                }
                .padding(.horizontal)
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
        .background(Color.blue.opacity(0.1))
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
            // Draw Card button: only when mustDrawCard is true (not during meld choice)
            if game.mustDrawCard && !game.awaitingMeldChoice && game.currentPlayer.type == .human {
                Button("Draw Card") {
                    withAnimation {
                        game.drawCardForCurrentPlayer()
                    }
                }
                .buttonStyle(.borderedProminent)
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
    
    // Draw pile stack view
    private var drawPileView: some View {
        HStack(spacing: -12) {
            ForEach(0..<min(game.deck.remainingCount, 5), id: \ .self) { i in
                Image("card_back")
                    .resizable()
                    .frame(width: 32, height: 48)
                    .cornerRadius(4)
                    .matchedGeometryEffect(id: "drawpile-\(i)", in: drawPileNamespace)
                    .opacity(Double(1.0 - Double(i) * 0.15))
            }
        }
        .padding(.vertical, 4)
    }
    
    // Dealer determination view
    private var dealerDeterminationView: some View {
        VStack(spacing: 15) {
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
                    
                    // Show drawn cards even when dealer is determined
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
    let playerNames: [String]
    let winningIndex: Int?
    @ObservedObject var game: Game
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Current Trick")
                .font(.headline)
                .foregroundColor(.secondary)
            if cards.isEmpty {
                Text("No cards played yet")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                HStack(spacing: 12) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                        let rotation = Double((index * 17) % 21 - 10) // -10 to +10 degrees
                        let zOffset = Double(index) * 2
                        VStack(spacing: 4) {
                            CardView(
                                card: card,
                                isSelected: false,
                                isPlayable: false
                            ) {
                                // No action for played cards
                            }
                            .overlay(
                                // Highlight winning card with a green border
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(winningIndex == index ? Color.green : Color.clear, lineWidth: 3)
                            )
                            .scaleEffect(winningIndex == index ? 1.05 : 1.0)
                            .shadow(color: winningIndex == index ? .green.opacity(0.5) : .clear, radius: 4)
                            .rotationEffect(.degrees(rotation))
                            .zIndex(Double(index))
                            .offset(y: zOffset)
                            if index < playerNames.count {
                                Text(playerNames[index])
                                    .font(.caption)
                                    .foregroundColor(winningIndex == index ? .green : .secondary)
                                    .fontWeight(winningIndex == index ? .bold : .regular)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
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