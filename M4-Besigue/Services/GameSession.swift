import Foundation
import Combine

/// GameSession manages multiplayer game sessions and state synchronization
class GameSession: ObservableObject {
    
    // MARK: - Published Properties
    @Published var sessionState: SessionState = .disconnected
    @Published var currentGame: NetworkGame?
    @Published var availableGames: [GameLobby] = []
    @Published var connectedPlayers: [PlayerConnection] = []
    @Published var isHost: Bool = false
    @Published var lastError: SessionError?
    
    // MARK: - Private Properties
    private let networkService: NetworkService
    private let playerId: UUID
    private let playerName: String
    private var cancellables = Set<AnyCancellable>()
    private var stateSyncTimer: Timer?
    
    // MARK: - Configuration
    private let stateSyncInterval: TimeInterval = 0.5 // Sync every 500ms during active gameplay
    private let lobbyRefreshInterval: TimeInterval = 2.0 // Refresh lobby every 2 seconds
    
    // MARK: - Initialization
    init(networkService: NetworkService, playerId: UUID, playerName: String) {
        self.networkService = networkService
        self.playerId = playerId
        self.playerName = playerName
        
        setupNetworkSubscriptions()
        setupStateSync()
    }
    
    deinit {
        leaveGame()
        stateSyncTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Connects to the network service
    func connect() {
        networkService.connect()
    }
    
    /// Disconnects from the network service
    func disconnect() {
        networkService.disconnect()
    }
    
    /// Creates a new multiplayer game
    func createGame(gameRules: GameRules) -> Bool {
        guard sessionState == .connected else {
            lastError = .notConnected
            return false
        }
        
        let gameId = UUID()
        let gameLobby = GameLobby(
            id: gameId,
            name: "\(playerName)'s Game",
            hostId: playerId,
            hostName: playerName,
            playerCount: gameRules.playerCount,
            gameRules: gameRules,
            status: .waiting,
            createdAt: Date()
        )
        
        let message = NetworkMessage(
            type: .createGame,
            senderId: playerId,
            data: .string(gameLobby.id.uuidString),
            gameId: gameId
        )
        
        networkService.sendMessage(message)
        sessionState = .creatingGame
        
        return true
    }
    
    /// Joins an existing multiplayer game
    func joinGame(_ gameLobby: GameLobby) -> Bool {
        guard sessionState == .connected else {
            lastError = .notConnected
            return false
        }
        
        let message = NetworkMessage(
            type: .joinGame,
            senderId: playerId,
            data: .string(gameLobby.id.uuidString),
            gameId: gameLobby.id
        )
        
        networkService.sendMessage(message)
        sessionState = .joiningGame
        
        return true
    }
    
    /// Leaves the current game
    func leaveGame() {
        guard let currentGame = currentGame else { return }
        
        let message = NetworkMessage(
            type: .leaveGame,
            senderId: playerId,
            data: nil,
            gameId: currentGame.id
        )
        
        networkService.sendMessage(message)
        
        // Clean up local state
        self.currentGame = nil
        sessionState = .connected
        isHost = false
        connectedPlayers.removeAll()
        
        // Stop state sync
        stateSyncTimer?.invalidate()
        stateSyncTimer = nil
    }
    
    /// Sends a player action to the network
    func sendPlayerAction(_ action: PlayerAction) {
        guard let currentGame = currentGame else { return }
        
        let actionData = PlayerActionData(
            playerId: playerId,
            actionType: action.type.rawValue,
            timestamp: Date(),
            metadata: action.metadata
        )
        
        let message = NetworkMessage(
            type: .playerAction,
            senderId: playerId,
            data: .playerAction(actionData),
            gameId: currentGame.id
        )
        
        networkService.sendMessage(message)
    }
    
    /// Sends a card action to the network
    func sendCardAction(_ action: CardAction) {
        guard let currentGame = currentGame else { return }
        
        let cardData = CardData(
            id: action.cardId,
            suit: action.suit.rawValue,
            rank: String(action.rank),
            isTrump: action.isTrump
        )
        
        let actionData = CardActionData(
            playerId: playerId,
            cardId: action.cardId,
            actionType: action.type.rawValue,
            position: action.position,
            timestamp: Date()
        )
        
        let message = NetworkMessage(
            type: .cardAction,
            senderId: playerId,
            data: .cardAction(actionData),
            gameId: currentGame.id
        )
        
        networkService.sendMessage(message)
    }
    
    /// Refreshes the list of available games
    func refreshAvailableGames() {
        // This would typically request a list from the server
        // For now, we'll just update the local state
        print("🔄 Refreshing available games")
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkSubscriptions() {
        // Subscribe to network service state changes
        networkService.$connectionState
            .sink { [weak self] state in
                DispatchQueue.main.async {
                    self?.handleNetworkStateChange(state)
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to network service errors
        networkService.$lastError
            .sink { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.handleNetworkError(error)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to network service connected players
        networkService.$connectedPlayers
            .sink { [weak self] players in
                DispatchQueue.main.async {
                    self?.connectedPlayers = players
                }
            }
            .store(in: &cancellables)
        
        // Listen for game state updates
        NotificationCenter.default.publisher(for: .gameStateUpdated)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.handleGameStateUpdate(notification.object)
                }
            }
            .store(in: &cancellables)
        
        // Listen for player actions
        NotificationCenter.default.publisher(for: .playerActionReceived)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.handlePlayerActionReceived(notification.object)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupStateSync() {
        // Set up periodic state synchronization during active gameplay
        stateSyncTimer = Timer.scheduledTimer(withTimeInterval: stateSyncInterval, repeats: true) { [weak self] _ in
            self?.syncGameState()
        }
        stateSyncTimer?.invalidate() // Start paused
    }
    
    private func handleNetworkStateChange(_ state: ConnectionState) {
        switch state {
        case .connected:
            sessionState = .connected
            print("🌐 Connected to game server")
            
        case .connecting:
            sessionState = .connecting
            print("🌐 Connecting to game server...")
            
        case .disconnected:
            sessionState = .disconnected
            print("🌐 Disconnected from game server")
            
            // Clean up game state
            currentGame = nil
            isHost = false
            connectedPlayers.removeAll()
            
        case .reconnecting:
            sessionState = .reconnecting
            print("🌐 Reconnecting to game server...")
        }
    }
    
    private func handleNetworkError(_ error: NetworkError) {
        lastError = .networkError(error)
        print("🌐 Network error: \(error)")
    }
    
    private func handleGameStateUpdate(_ object: Any?) {
        guard let gameStateData = object as? GameStateData else { return }
        
        // Update the current game state
        if let currentGame = currentGame {
            currentGame.updateFromNetworkState(gameStateData)
        }
        
        print("🔄 Game state updated from network")
    }
    
    private func handlePlayerActionReceived(_ object: Any?) {
        guard let actionData = object as? PlayerActionData else { return }
        
        // Handle player actions from other players
        print("🎮 Player action received: \(actionData.actionType) from \(actionData.playerId)")
        
        // This would typically update the local game state
        // based on the received action
    }
    
    private func syncGameState() {
        guard let currentGame = currentGame,
              sessionState == .inGame else { return }
        
        // Send current game state to other players
        let gameStateData = currentGame.createNetworkState()
        let message = NetworkMessage(
            type: .gameStateUpdate,
            senderId: playerId,
            data: .gameState(gameStateData),
            gameId: currentGame.id
        )
        
        networkService.sendMessage(message)
    }
    
    private func startStateSync() {
        stateSyncTimer?.invalidate()
        stateSyncTimer = Timer.scheduledTimer(withTimeInterval: stateSyncInterval, repeats: true) { [weak self] _ in
            self?.syncGameState()
        }
    }
    
    private func stopStateSync() {
        stateSyncTimer?.invalidate()
        stateSyncTimer = nil
    }
}

// MARK: - Supporting Types

enum SessionState {
    case disconnected
    case connecting
    case connected
    case creatingGame
    case joiningGame
    case inGame
    case reconnecting
}

enum SessionError: Error, LocalizedError {
    case notConnected
    case gameNotFound
    case gameFull
    case invalidGameState
    case networkError(NetworkError)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to game server"
        case .gameNotFound:
            return "Game not found"
        case .gameFull:
            return "Game is full"
        case .invalidGameState:
            return "Invalid game state"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

struct GameLobby: Codable, Identifiable {
    let id: UUID
    let name: String
    let hostId: UUID
    let hostName: String
    let playerCount: Int
    let gameRules: GameRules
    let status: GameStatus
    let createdAt: Date
    var currentPlayers: Int = 1
}

enum GameStatus: String, Codable, CaseIterable {
    case waiting = "waiting"
    case starting = "starting"
    case inProgress = "in_progress"
    case finished = "finished"
}

struct PlayerAction {
    let type: PlayerActionType
    let metadata: [String: String]
}

enum PlayerActionType: String, CaseIterable {
    case ready = "ready"
    case notReady = "not_ready"
    case leave = "leave"
    case chat = "chat"
}

struct CardAction {
    let type: CardActionType
    let cardId: UUID
    let suit: Suit
    let rank: Int
    let isTrump: Bool
    let position: Int?
}

enum CardActionType: String, CaseIterable {
    case play = "play"
    case draw = "draw"
    case discard = "discard"
    case meld = "meld"
} 