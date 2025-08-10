import Foundation
import Network

/// NetworkService handles WebSocket connections and message routing for multiplayer games
class NetworkService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var connectionState: ConnectionState = .disconnected
    @Published var connectedPlayers: [PlayerConnection] = []
    @Published var lastError: NetworkError?
    
    // MARK: - Private Properties
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private var messageQueue: [NetworkMessage] = []
    private var isReconnecting = false
    private var reconnectTimer: Timer?
    
    // MARK: - Configuration
    private let serverURL: URL
    private let reconnectInterval: TimeInterval = 5.0
    private let maxReconnectAttempts = 3
    private var reconnectAttempts = 0
    
    // MARK: - Initialization
    init(serverURL: URL) {
        self.serverURL = serverURL
        self.urlSession = URLSession(configuration: .default)
        print("🌐 NetworkService initialized with server: \(serverURL)")
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Connection Management
    
    /// Connects to the game server
    func connect() {
        guard connectionState == .disconnected else {
            print("🌐 Already connected or connecting")
            return
        }
        
        print("🌐 Attempting to connect to \(serverURL)")
        connectionState = .connecting
        
        let request = URLRequest(url: serverURL)
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Start listening for messages
        receiveMessage()
        
        // Set connection timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            if self?.connectionState == .connecting {
                self?.handleConnectionTimeout()
            }
        }
    }
    
    /// Disconnects from the game server
    func disconnect() {
        print("🌐 Disconnecting from server")
        
        webSocketTask?.cancel()
        webSocketTask = nil
        connectionState = .disconnected
        connectedPlayers.removeAll()
        
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        isReconnecting = false
        reconnectAttempts = 0
    }
    
    /// Sends a message to the server
    func sendMessage(_ message: NetworkMessage) {
        guard connectionState == .connected else {
            print("🌐 Cannot send message - not connected")
            messageQueue.append(message)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let webSocketMessage = URLSessionWebSocketTask.Message.data(data)
            
            webSocketTask?.send(webSocketMessage) { [weak self] error in
                if let error = error {
                    print("🌐 Failed to send message: \(error)")
                    self?.handleSendError(error)
                } else {
                    print("🌐 Message sent successfully: \(message.type)")
                }
            }
        } catch {
            print("🌐 Failed to encode message: \(error)")
            lastError = .encodingError(error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    self?.handleReceivedMessage(message)
                    // Continue listening for more messages
                    self?.receiveMessage()
                    
                case .failure(let error):
                    print("🌐 Receive error: \(error)")
                    self?.handleReceiveError(error)
                }
            }
        }
    }
    
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            do {
                let networkMessage = try JSONDecoder().decode(NetworkMessage.self, from: data)
                print("🌐 Received message: \(networkMessage.type)")
                processNetworkMessage(networkMessage)
            } catch {
                print("🌐 Failed to decode message: \(error)")
                lastError = .decodingError(error.localizedDescription)
            }
            
        case .string(let string):
            print("🌐 Received string message: \(string)")
            // Handle string messages if needed
            
        @unknown default:
            print("🌐 Unknown message type received")
        }
    }
    
    private func processNetworkMessage(_ message: NetworkMessage) {
        switch message.type {
        case .connectionEstablished:
            handleConnectionEstablished(message)
        case .playerJoined:
            handlePlayerJoined(message)
        case .playerLeft:
            handlePlayerLeft(message)
        case .gameStateUpdate:
            handleGameStateUpdate(message)
        case .playerAction:
            handlePlayerAction(message)
        case .cardAction:
            handleCardAction(message)
        case .error:
            handleError(message)
        case .createGame, .joinGame, .leaveGame, .gameCreated, .gameJoined, .gameLeft:
            // These are handled by the game session
            break
        case .gameStarted, .gameEnded, .roundStarted, .roundEnded:
            // These are handled by the game engine
            break
        case .cardPlayed, .cardDrawn, .meldDeclared, .dealerDetermined:
            // These are handled by the game engine
            break
        case .chatMessage, .systemMessage:
            // These are handled by the UI
            break
        case .ping, .pong:
            // Keep-alive messages
            break
        }
    }
    
    private func handleConnectionEstablished(_ message: NetworkMessage) {
        print("🌐 Connection established with server")
        connectionState = .connected
        reconnectAttempts = 0
        
        // Send any queued messages
        while !messageQueue.isEmpty {
            let queuedMessage = messageQueue.removeFirst()
            sendMessage(queuedMessage)
        }
    }
    
    private func handlePlayerJoined(_ message: NetworkMessage) {
        guard let playerData = message.data as? PlayerConnection else { return }
        
        if !connectedPlayers.contains(where: { $0.id == playerData.id }) {
            connectedPlayers.append(playerData)
            print("🌐 Player joined: \(playerData.name)")
        }
    }
    
    private func handlePlayerLeft(_ message: NetworkMessage) {
        guard let playerId = message.data as? UUID else { return }
        
        connectedPlayers.removeAll { $0.id == playerId }
        print("🌐 Player left: \(playerId)")
    }
    
    private func handleGameStateUpdate(_ message: NetworkMessage) {
        // This will be handled by the game engine
        NotificationCenter.default.post(
            name: .gameStateUpdated,
            object: message.data
        )
    }
    
    private func handlePlayerAction(_ message: NetworkMessage) {
        // This will be handled by the game engine
        NotificationCenter.default.post(
            name: .playerActionReceived,
            object: message.data
        )
    }
    
    private func handleCardAction(_ message: NetworkMessage) {
        // This will be handled by the game engine
        NotificationCenter.default.post(
            name: .cardActionReceived,
            object: message.data
        )
    }
    
    private func handleError(_ message: NetworkMessage) {
        if let errorData = message.data as? NetworkError {
            lastError = errorData
            print("🌐 Network error: \(errorData)")
        }
    }
    
    private func handleConnectionTimeout() {
        print("🌐 Connection timeout")
        connectionState = .disconnected
        lastError = .connectionTimeout
        attemptReconnect()
    }
    
    private func handleSendError(_ error: Error) {
        print("🌐 Send error: \(error)")
        lastError = .sendError(error.localizedDescription)
    }
    
    private func handleReceiveError(_ error: Error) {
        print("🌐 Receive error: \(error)")
        lastError = .receiveError(error.localizedDescription)
        connectionState = .disconnected
        attemptReconnect()
    }
    
    private func attemptReconnect() {
        guard !isReconnecting && reconnectAttempts < maxReconnectAttempts else {
            if reconnectAttempts >= maxReconnectAttempts {
                print("🌐 Max reconnection attempts reached")
                lastError = .maxReconnectAttemptsReached
            }
            return
        }
        
        isReconnecting = true
        reconnectAttempts += 1
        
        print("🌐 Attempting reconnection \(reconnectAttempts)/\(maxReconnectAttempts)")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: false) { [weak self] _ in
            self?.isReconnecting = false
            self?.connect()
        }
    }
}

// MARK: - Supporting Types

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting
}

enum NetworkError: Error, LocalizedError, Codable {
    case connectionTimeout
    case sendError(String)
    case receiveError(String)
    case encodingError(String)
    case decodingError(String)
    case maxReconnectAttemptsReached
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .connectionTimeout:
            return "Connection to server timed out"
        case .sendError(let error):
            return "Failed to send message: \(error)"
        case .receiveError(let error):
            return "Failed to receive message: \(error)"
        case .encodingError(let error):
            return "Failed to encode message: \(error)"
        case .decodingError(let error):
            return "Failed to decode message: \(error)"
        case .maxReconnectAttemptsReached:
            return "Maximum reconnection attempts reached"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let gameStateUpdated = Notification.Name("gameStateUpdated")
    static let playerActionReceived = Notification.Name("playerActionReceived")
    static let cardActionReceived = Notification.Name("cardActionReceived")
    static let cardPlayed = Notification.Name("cardPlayed")
    static let cardDrawn = Notification.Name("cardDrawn")
} 