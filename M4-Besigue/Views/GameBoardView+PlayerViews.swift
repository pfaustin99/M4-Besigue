import SwiftUI

// MARK: - GameBoardView Player Views Extension
extension GameBoardView {
    
    // MARK: - Player Name View
    /// Creates the player name view
    /// - Parameters:
    ///   - index: Player index
    ///   - position: Position to place the view
    /// - Returns: Player name view
    func gamePlayerNameView(for index: Int, at position: CGPoint) -> some View {
        let player = self.game.players[index]
        let isCurrentPlayer = index == self.game.currentPlayerIndex
        
        return Text(player.name)
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(6)
            .background(isCurrentPlayer ? GameBoardConstants.Colors.primaryGreen : GameBoardConstants.Colors.primaryRed)
            .cornerRadius(GameBoardConstants.cornerRadius)
            .shadow(color: GameBoardConstants.Colors.primaryGold, radius: GameBoardConstants.shadowRadius, x: 1, y: 1)
            .position(position)
    }
    
    // MARK: - Player Hand View
    /// Creates the player hand view
    /// - Parameters:
    ///   - index: Player index
    ///   - position: Position to place the view
    ///   - isHorizontal: Whether the hand is horizontal
    ///   - angle: Rotation angle
    /// - Returns: Player hand view
    func gamePlayerHandView(for index: Int, at position: CGPoint, isHorizontal: Bool, angle: Double) -> some View {
        let player = self.game.players[index]
        let isCurrentPlayer = index == self.game.currentPlayerIndex
        
        return Group {
            if isCurrentPlayer && !player.held.isEmpty {
                // Current player: show actual cards without scrolling
                currentPlayerHandView(player: player, isHorizontal: isHorizontal)
            } else if game.currentPhase == .setup {
                // Setup phase: show placeholder
                setupPhaseHandView()
            } else {
                // Other players: show card backs oriented as if held by that player
                otherPlayerHandView(player: player, isHorizontal: isHorizontal, angle: angle)
            }
        }
        .position(position)
    }
    
    /// Creates the current player's hand view
    /// - Parameters:
    ///   - player: The current player
    ///   - isHorizontal: Whether the hand is horizontal
    /// - Returns: Current player hand view
    private func currentPlayerHandView(player: Player, isHorizontal: Bool) -> some View {
        let frame = getHandFrame(isHorizontal: isHorizontal)
        
        return HStack(spacing: GameBoardConstants.cardSpacing) {
            ForEach(player.held) { card in
                let isSelected = viewState.isCardSelected(card)
                CardView(
                    card: card,
                    isSelected: isSelected,
                    isPlayable: true,
                    showHint: false
                ) {
                    handleCardSelection(card)
                }
                .onTapGesture(count: 2) {
                    handleCardPlayed(card)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .shadow(color: isSelected ? GameBoardConstants.Colors.selectedCardShadow : .clear, 
                       radius: isSelected ? GameBoardConstants.cardShadowRadius : 0)
                .animation(.easeInOut(duration: GameBoardConstants.cardSelectionAnimationDuration), value: isSelected)
            }
        }
        .frame(width: frame.width, height: frame.height)
    }
    
    /// Creates the setup phase hand view
    /// - Returns: Setup phase placeholder view
    private func setupPhaseHandView() -> some View {
        Text("Setup Phase")
            .font(.caption)
            .foregroundColor(.gray)
            .padding(8)
            .background(Color.white.opacity(0.8))
            .cornerRadius(GameBoardConstants.cornerRadius)
    }
    
    /// Creates other players' hand view
    /// - Parameters:
    ///   - player: The player
    ///   - isHorizontal: Whether the hand is horizontal
    ///   - angle: Rotation angle
    /// - Returns: Other player hand view
    private func otherPlayerHandView(player: Player, isHorizontal: Bool, angle: Double) -> some View {
        VStack {
            if isHorizontal {
                HStack(spacing: -40) {
                    ForEach(0..<player.held.count, id: \.self) { cardIndex in
                        CardBackView { }
                            .frame(width: GameBoardConstants.smallCardWidth, height: GameBoardConstants.smallCardHeight)
                            .rotationEffect(.degrees(180 + getCardRotation(for: angle)))
                            .offset(x: CGFloat(cardIndex) * GameBoardConstants.cardOverlap)
                    }
                }
            } else {
                VStack(spacing: -60) {
                    ForEach(0..<player.held.count, id: \.self) { cardIndex in
                        CardBackView { }
                            .frame(width: GameBoardConstants.smallCardWidth, height: GameBoardConstants.smallCardHeight)
                            .rotationEffect(.degrees(180 + getCardRotation(for: angle)))
                            .offset(y: CGFloat(cardIndex) * GameBoardConstants.cardOverlap)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: GameBoardConstants.cornerRadius)
                .fill(GameBoardConstants.Colors.meldBackground)
                .stroke(GameBoardConstants.Colors.primaryGreen, lineWidth: GameBoardConstants.thinStrokeWidth)
        )
    }
    
    // MARK: - Player Meld View
    /// Creates the player meld view
    /// - Parameters:
    ///   - index: Player index
    ///   - position: Position to place the view
    ///   - isHorizontal: Whether the meld is horizontal
    /// - Returns: Player meld view
    func gamePlayerMeldView(for index: Int, at position: CGPoint, isHorizontal: Bool) -> some View {
        let player = self.game.players[index]
        
        return Group {
            if !player.melded.isEmpty {
                // Show actual melded cards with existing badging system
                meldedCardsView(player: player, isHorizontal: isHorizontal)
            } else {
                // Show placeholder for no melds
                noMeldsView()
            }
        }
        .position(position)
    }
    
    /// Creates the melded cards view
    /// - Parameters:
    ///   - player: The player
    ///   - isHorizontal: Whether the meld is horizontal
    /// - Returns: Melded cards view
    private func meldedCardsView(player: Player, isHorizontal: Bool) -> some View {
        VStack {
            if isHorizontal {
                HStack(spacing: GameBoardConstants.meldCardSpacing) {
                    ForEach(player.getMeldedCardsInOrder(), id: \.id) { card in
                        meldedCardView(card: card)
                    }
                }
            } else {
                VStack(spacing: GameBoardConstants.meldCardSpacing) {
                    ForEach(player.getMeldedCardsInOrder(), id: \.id) { card in
                        meldedCardView(card: card)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: GameBoardConstants.cornerRadius)
                .fill(GameBoardConstants.Colors.meldBackground)
                .stroke(GameBoardConstants.Colors.primaryGreen, lineWidth: GameBoardConstants.thinStrokeWidth)
        )
    }
    
    /// Creates a single melded card view
    /// - Parameter card: The card to display
    /// - Returns: Melded card view
    private func meldedCardView(card: PlayerCard) -> some View {
        VStack(spacing: 2) {
            // Card face
            Image(card.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: GameBoardConstants.meldCardWidth, height: GameBoardConstants.meldCardHeight)
                .cornerRadius(4)
            
            // Badge row (simplified for smaller cards)
            HStack(spacing: GameBoardConstants.badgeSpacing) {
                ForEach(0..<min(2, card.usedInMeldTypes.count), id: \.self) { badgeIndex in
                    let meldType = Array(card.usedInMeldTypes)[badgeIndex]
                    Text(badgeIcon(for: meldType, card: card))
                        .font(.system(size: GameBoardConstants.FontSizes.badge, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: GameBoardConstants.badgeSize, height: GameBoardConstants.badgeSize)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
        }
    }
    
    /// Creates the no melds placeholder view
    /// - Returns: No melds placeholder
    private func noMeldsView() -> some View {
        Text("No Melds")
            .font(.caption2)
            .foregroundColor(.gray)
            .padding(4)
            .background(Color.white.opacity(0.8))
            .cornerRadius(4)
    }
    
    // MARK: - Scoreboard Views
    /// Creates the game scoreboard view
    /// - Parameters:
    ///   - game: The game object
    ///   - settings: The settings object
    /// - Returns: Game scoreboard view
    func GameScoreboardView(game: Game, settings: GameSettings) -> some View {
        VStack(spacing: GameBoardConstants.scoreboardSpacing) {
            Text("BÉSIGUE - \(game.players.count) Players")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(GameBoardConstants.Colors.primaryRed)
                .shadow(color: GameBoardConstants.Colors.primaryGold, radius: 1, x: 0.5, y: 0.5)
            
            gameScoreboardGrid(game: game)
        }
        .padding()
        .background(GameBoardConstants.Colors.scoreBackground)
        .shadow(radius: GameBoardConstants.shadowRadius)
    }
    
    /// Creates the scoreboard grid
    /// - Parameter game: The game object
    /// - Returns: Scoreboard grid view
    private func gameScoreboardGrid(game: Game) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: game.players.count), spacing: GameBoardConstants.scoreboardSpacing) {
            ForEach(0..<game.players.count, id: \.self) { index in
                gamePlayerScoreCard(player: game.players[index], isCurrentPlayer: index == game.currentPlayerIndex)
            }
        }
        .padding(.horizontal)
    }
    
    /// Creates a player score card
    /// - Parameters:
    ///   - player: The player
    ///   - isCurrentPlayer: Whether this is the current player
    /// - Returns: Player score card view
    private func gamePlayerScoreCard(player: Player, isCurrentPlayer: Bool) -> some View {
        VStack(spacing: 4) {
            Text(player.name)
                .font(.caption)
                .fontWeight(.medium)
                .shadow(color: GameBoardConstants.Colors.primaryGold, radius: 1, x: 0.5, y: 0.5)
            
            HStack(spacing: 8) {
                Text("Score: \(player.score)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, GameBoardConstants.verticalPadding)
                    .background(GameBoardConstants.Colors.scoreBackgroundGold)
                    .cornerRadius(4)
                
                Text("Tricks: \(player.tricksWon)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, GameBoardConstants.verticalPadding)
                    .background(GameBoardConstants.Colors.scoreBackgroundRed)
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(isCurrentPlayer ? GameBoardConstants.Colors.currentPlayerBackground : GameBoardConstants.Colors.otherPlayerBackground)
        .cornerRadius(GameBoardConstants.cornerRadius)
    }
} 