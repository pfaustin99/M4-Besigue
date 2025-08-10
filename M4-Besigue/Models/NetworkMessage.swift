import Foundation

/// NetworkMessage defines all network communication protocols for multiplayer games
struct NetworkMessage: Codable {
    let id: UUID
    let type: MessageType
    let senderId: UUID
    let timestamp: Date
    let data: MessageData?
    let gameId: UUID?
    
    init(type: MessageType, senderId: UUID, data: MessageData? = nil, gameId: UUID? = nil) {
        self.id = UUID()
        self.type = type
        self.senderId = senderId
        self.timestamp = Date()
        self.data = data
        self.gameId = gameId
    }
}

// MARK: - Message Types

enum MessageType: String, Codable, CaseIterable {
    // Connection messages
    case connectionEstablished = "connection_established"
    case playerJoined = "player_joined"
    case playerLeft = "player_left"
    
    // Game session messages
    case createGame = "create_game"
    case joinGame = "join_game"
    case leaveGame = "leave_game"
    case gameCreated = "game_created"
    case gameJoined = "game_joined"
    case gameLeft = "game_left"
    
    // Game state messages
    case gameStateUpdate = "game_state_update"
    case gameStarted = "game_started"
    case gameEnded = "game_ended"
    case roundStarted = "round_started"
    case roundEnded = "round_ended"
    
    // Player action messages
    case playerAction = "player_action"
    case cardAction = "card_action"
    case cardPlayed = "card_played"
    case cardDrawn = "card_drawn"
    case meldDeclared = "meld_declared"
    case dealerDetermined = "dealer_determined"
    
    // Chat and system messages
    case chatMessage = "chat_message"
    case systemMessage = "system_message"
    case error = "error"
    
    // Keep-alive and ping
    case ping = "ping"
    case pong = "pong"
}

// MARK: - Message Data

enum MessageData: Codable {
    case playerConnection(PlayerConnection)
    case gameState(GameStateData)
    case playerAction(PlayerActionData)
    case cardAction(CardActionData)
    case meldAction(MeldActionData)
    case chatMessage(ChatMessageData)
    case systemMessage(SystemMessageData)
    case error(NetworkError)
    case string(String)
    case data(Data)
    
    // Custom coding keys for type-safe encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case type, payload
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "playerConnection":
            let payload = try container.decode(PlayerConnection.self, forKey: .payload)
            self = .playerConnection(payload)
        case "gameState":
            let payload = try container.decode(GameStateData.self, forKey: .payload)
            self = .gameState(payload)
        case "playerAction":
            let payload = try container.decode(PlayerActionData.self, forKey: .payload)
            self = .playerAction(payload)
        case "cardAction":
            let payload = try container.decode(CardActionData.self, forKey: .payload)
            self = .cardAction(payload)
        case "meldAction":
            let payload = try container.decode(MeldActionData.self, forKey: .payload)
            self = .meldAction(payload)
        case "chatMessage":
            let payload = try container.decode(ChatMessageData.self, forKey: .payload)
            self = .chatMessage(payload)
        case "systemMessage":
            let payload = try container.decode(SystemMessageData.self, forKey: .payload)
            self = .systemMessage(payload)
        case "error":
            let payload = try container.decode(NetworkError.self, forKey: .payload)
            self = .error(payload)
        case "string":
            let payload = try container.decode(String.self, forKey: .payload)
            self = .string(payload)
        case "data":
            let payload = try container.decode(Data.self, forKey: .payload)
            self = .data(payload)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown message data type: \(type)"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .playerConnection(let payload):
            try container.encode("playerConnection", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .gameState(let payload):
            try container.encode("gameState", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .playerAction(let payload):
            try container.encode("playerAction", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .cardAction(let payload):
            try container.encode("cardAction", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .meldAction(let payload):
            try container.encode("meldAction", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .chatMessage(let payload):
            try container.encode("chatMessage", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .systemMessage(let payload):
            try container.encode("systemMessage", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .error(let payload):
            try container.encode("error", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .string(let payload):
            try container.encode("string", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .data(let payload):
            try container.encode("data", forKey: .type)
            try container.encode(payload, forKey: .payload)
        }
    }
}

// MARK: - Supporting Data Types

struct PlayerConnection: Codable, Identifiable {
    let id: UUID
    let name: String
    let isHost: Bool
    let isReady: Bool
    let connectionTime: Date
    let lastSeen: Date
}

struct GameStateData: Codable {
    let gameId: UUID
    let phase: String
    let currentPlayerIndex: Int
    let players: [PlayerStateData]
    let currentTrick: [CardData]
    let deckCount: Int
    let roundNumber: Int
    let scores: [UUID: Int]
}

struct PlayerStateData: Codable {
    let id: UUID
    let name: String
    let handCount: Int
    let meldedCards: [CardData]
    let isCurrentPlayer: Bool
    let isDealer: Bool
    let score: Int
    let tricksWon: Int
}

struct CardData: Codable {
    let id: UUID
    let suit: String
    let rank: String
    let isTrump: Bool
}

struct PlayerActionData: Codable {
    let playerId: UUID
    let actionType: String
    let timestamp: Date
    let metadata: [String: String]
}

struct CardActionData: Codable {
    let playerId: UUID
    let cardId: UUID
    let actionType: String // "play", "draw", "discard"
    let position: Int?
    let timestamp: Date
}

struct MeldActionData: Codable {
    let playerId: UUID
    let meldType: String
    let cards: [CardData]
    let points: Int
    let timestamp: Date
}

struct ChatMessageData: Codable {
    let playerId: UUID
    let playerName: String
    let message: String
    let timestamp: Date
    let isSystemMessage: Bool
}

struct SystemMessageData: Codable {
    let message: String
    let severity: String // "info", "warning", "error"
    let timestamp: Date
    let targetPlayerId: UUID?
} 