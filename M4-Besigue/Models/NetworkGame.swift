import Foundation

/// NetworkGame extends the existing Game class to add multiplayer network functionality
class NetworkGame: Game {
    
    // MARK: - Network Properties
    let id: UUID
    let hostId: UUID
    var networkPlayers: [NetworkPlayer] = []
    var lastNetworkSync: Date = Date()
    var isNetworkAuthoritative: Bool = false
    
    // MARK: - Network State
    private var pendingActions: [NetworkAction] = []
    private var actionSequenceNumber: Int = 0
    private var lastProcessedSequence: Int = -1
    
    // MARK: - Initialization
    init(gameRules: GameRules, hostId: UUID, isOnline: Bool = true) {
        self.id = UUID()
        self.hostId = hostId
        super.init(gameRules: gameRules, isOnline: isOnline)
        
        print("🌐 NetworkGame created with ID: \(id)")
        setupNetworkPlayers()
    }
    
    // MARK: - Network Player Management
    
    private func setupNetworkPlayers() {
        // Convert existing players to network players
        networkPlayers = players.map { player in
            NetworkPlayer(
                id: player.id,
                name: player.name,
                type: player.type,
                isHost: player.id == hostId,
                isConnected: true,
                lastSeen: Date()
            )
        }
    }
    
    /// Adds a new network player to the game
    func addNetworkPlayer(_ playerConnection: PlayerConnection) {
        let networkPlayer = NetworkPlayer(
            id: playerConnection.id,
            name: playerConnection.name,
            type: .human, // Network players are always human
            isHost: playerConnection.isHost,
            isConnected: true,
            lastSeen: Date()
        )
        
        networkPlayers.append(networkPlayer)
        
        // Create corresponding game player
        let gamePlayer = Player(
            name: playerConnection.name,
            type: .human
        )
        gamePlayer.id = playerConnection.id // Set the same ID for consistency
        
        players.append(gamePlayer)
        
        print("🌐 Added network player: \(playerConnection.name)")
    }
    
    /// Removes a network player from the game
    func removeNetworkPlayer(_ playerId: UUID) {
        // Remove from network players
        networkPlayers.removeAll { $0.id == playerId }
        
        // Remove from game players
        players.removeAll { $0.id == playerId }
        
        print("🌐 Removed network player: \(playerId)")
    }
    
    /// Updates player connection status
    func updatePlayerConnection(_ playerId: UUID, isConnected: Bool) {
        if let index = networkPlayers.firstIndex(where: { $0.id == playerId }) {
            networkPlayers[index].isConnected = isConnected
            networkPlayers[index].lastSeen = Date()
        }
        
        print("🌐 Player \(playerId) connection status: \(isConnected)")
    }
    
    // MARK: - Network State Synchronization
    
    /// Creates a network state representation for synchronization
    func createNetworkState() -> GameStateData {
        let playerStates = players.map { player in
            PlayerStateData(
                id: player.id,
                name: player.name,
                handCount: player.hand.count,
                meldedCards: player.melded.map { card in
                    CardData(
                        id: card.id,
                        suit: card.suit?.rawValue ?? "",
                        rank: String(card.rank),
                        isTrump: card.suit == trumpSuit
                    )
                },
                isCurrentPlayer: player.isCurrentPlayer,
                isDealer: player.isDealer,
                score: player.totalPoints,
                tricksWon: player.tricksWon
            )
        }
        
        let currentTrickCards = currentTrick.map { card in
            CardData(
                id: card.id,
                suit: card.suit?.rawValue ?? "",
                rank: String(card.rank),
                isTrump: card.suit == trumpSuit
            )
        }
        
        let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0.totalPoints) })
        
        return GameStateData(
            gameId: id,
            phase: currentPhase.rawValue,
            currentPlayerIndex: currentPlayerIndex,
            players: playerStates,
            currentTrick: currentTrickCards,
            deckCount: deck.remainingCount,
            roundNumber: roundNumber,
            scores: scores
        )
    }
    
    /// Updates the game state from network data
    func updateFromNetworkState(_ gameStateData: GameStateData) {
        // Only update if this is not the authoritative client
        guard !isNetworkAuthoritative else { return }
        
        print("🔄 Updating game state from network")
        
        // Update game phase
        if let phase = GamePhase(rawValue: gameStateData.phase) {
            currentPhase = phase
        }
        
        // Update current player
        currentPlayerIndex = gameStateData.currentPlayerIndex
        
        // Update player states
        for (index, playerState) in gameStateData.players.enumerated() {
            if index < players.count {
                let player = players[index]
                player.isCurrentPlayer = playerState.isCurrentPlayer
                player.isDealer = playerState.isDealer
                player.score = playerState.score
                player.tricksWon = playerState.tricksWon
                
                // Update hand count (but not actual cards for security)
                if player.hand.count != playerState.handCount {
                    print("🔄 Player \(player.name) hand count updated: \(player.hand.count) -> \(playerState.handCount)")
                }
            }
        }
        
        // Update current trick (but not actual cards for security)
        if currentTrick.count != gameStateData.currentTrick.count {
            print("🔄 Current trick count updated: \(currentTrick.count) -> \(gameStateData.currentTrick.count)")
        }
        
        // Update round number
        roundNumber = gameStateData.roundNumber
        
        // Update scores
        for (playerId, score) in gameStateData.scores {
            if let player = players.first(where: { $0.id == playerId }) {
                player.score = score
            }
        }
        
        lastNetworkSync = Date()
    }
    
    // MARK: - Network Action Processing
    
    /// Processes a network action from another player
    func processNetworkAction(_ action: NetworkAction) {
        // Check sequence number to ensure proper ordering
        if action.sequenceNumber <= lastProcessedSequence {
            print("🔄 Skipping old action: \(action.sequenceNumber) <= \(lastProcessedSequence)")
            return
        }
        
        print("🔄 Processing network action: \(action.type) from \(action.playerId)")
        
        // Process the action based on type
        switch action.type {
        case .cardPlayed:
            processCardPlayedAction(action)
        case .cardDrawn:
            processCardDrawnAction(action)
        case .meldDeclared:
            processMeldDeclaredAction(action)
        case .dealerDetermined:
            processDealerDeterminedAction(action)
        case .playerReady:
            // Handle player ready action
            print("🔄 Player ready action received")
        case .playerNotReady:
            // Handle player not ready action
            print("🔄 Player not ready action received")
        }
        
        lastProcessedSequence = action.sequenceNumber
    }
    
    private func processCardPlayedAction(_ action: NetworkAction) {
        guard let cardData = action.data as? CardData,
              let player = players.first(where: { $0.id == action.playerId }) else { return }
        
        // Find the card in the player's hand
        if let cardIndex = player.hand.firstIndex(where: { $0.id == cardData.id }) {
            let card = player.hand[cardIndex]
            player.removeCard(card)
            currentTrick.append(card)
            
            print("🔄 Network card played: \(card.displayName) by \(player.name)")
        }
    }
    
    private func processCardDrawnAction(_ action: NetworkAction) {
        guard let player = players.first(where: { $0.id == action.playerId }) else { return }
        
        // Mark player as having drawn
        hasDrawnForNextTrick[player.id] = true
        
        print("🔄 Network card drawn by: \(player.name)")
    }
    
    private func processMeldDeclaredAction(_ action: NetworkAction) {
        guard let meldData = action.data as? MeldActionData,
              let player = players.first(where: { $0.id == action.playerId }) else { return }
        
        // Process meld declaration
        // This would need to be implemented based on your meld system
        print("🔄 Network meld declared: \(meldData.meldType) by \(player.name)")
    }
    
    private func processDealerDeterminedAction(_ action: NetworkAction) {
        // Update dealer determination
        print("🔄 Network dealer determined")
        // This would update the dealer state
    }
    
    // MARK: - Override Methods for Network Integration
    
    override func playCard(_ card: PlayerCard, from player: Player) {
        // Call the original implementation
        super.playCard(card, from: player)
        
        // Create and queue network action
        let action = NetworkAction(
            type: .cardPlayed,
            playerId: player.id,
            sequenceNumber: getNextSequenceNumber(),
            data: CardData(
                id: card.id,
                suit: card.suit?.rawValue ?? "",
                rank: String(card.rank),
                isTrump: card.suit == trumpSuit
            )
        )
        
        pendingActions.append(action)
        print("🌐 Queued network action: \(action.type)")
    }
    

    
    // MARK: - Private Methods
    
    private func getNextSequenceNumber() -> Int {
        actionSequenceNumber += 1
        return actionSequenceNumber
    }
}

// MARK: - Supporting Types

struct NetworkPlayer: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: PlayerType
    let isHost: Bool
    var isConnected: Bool
    var lastSeen: Date
}

struct NetworkAction: Codable {
    let type: NetworkActionType
    let playerId: UUID
    let sequenceNumber: Int
    let data: Data?
    let timestamp: Date
    
    init(type: NetworkActionType, playerId: UUID, sequenceNumber: Int, data: Codable?) {
        self.type = type
        self.playerId = playerId
        self.sequenceNumber = sequenceNumber
        if let data = data {
            do {
                self.data = try JSONEncoder().encode(data)
            } catch {
                print("Failed to encode data: \(error)")
                self.data = nil
            }
        } else {
            self.data = nil
        }
        self.timestamp = Date()
    }
    
    func decodeData<T: Codable>(as type: T.Type) -> T? {
        guard let data = data else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode data: \(error)")
            return nil
        }
    }
}

enum NetworkActionType: String, Codable, CaseIterable {
    case cardPlayed = "card_played"
    case cardDrawn = "card_drawn"
    case meldDeclared = "meld_declared"
    case dealerDetermined = "dealer_determined"
    case playerReady = "player_ready"
    case playerNotReady = "player_not_ready"
} 