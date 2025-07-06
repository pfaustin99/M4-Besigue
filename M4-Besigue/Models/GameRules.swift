import Foundation

/// Enum for trick area size
enum TrickAreaSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}

/// Enum for dealer determination method
@objc enum DealerDeterminationMethod: Int, CaseIterable, Codable, Identifiable {
    case drawJacks
    case random
    
    var id: Int { rawValue }
    var displayName: String {
        switch self {
        case .drawJacks: return "Draw Jacks"
        case .random: return "Random (default)"
        }
    }
}

/// Enum for player type
enum PlayerType: String, CaseIterable, Codable {
    case human
    case ai
}

/// Player configuration for game setup
struct PlayerConfiguration: Identifiable, Codable {
    let id = UUID()
    var name: String
    var type: PlayerType
    var position: Int // 0-based position at table
    
    init(name: String, type: PlayerType, position: Int) {
        self.name = name
        self.type = type
        self.position = position
    }
}

/// GameRules holds game settings that affect all future games
class GameRules: ObservableObject, Codable, Equatable {
    // TODO: After gameplay is complete, revisit and improve the 'draw jacks' dealer determination logic and UI as discussed with the user.
    
    // Haitian cities for AI names
    static let haitianCities = [
        "Port-au-Prince", "Cap-Haïtien", "Gonaïves", "Les Cayes", "Petion-Ville",
        "Saint-Marc", "Carrefour", "Delmas", "Cité Soleil", "Kenscoff",
        "Tabarre", "Thomazeau", "Fort-Liberté", "Limbé", "Plaine-du-Nord",
        "Milot", "Saint-Michel-de-l'Attalaye", "Marmelade", "Gros-Morne",
        "Port-Salut", "Camp-Perrin", "Torbeck", "Hinche", "Mirebalais",
        "Lascahobas", "Jacmel", "Marigot", "Belle-Anse", "Miragoâne",
        "Anse-à-Veau", "Baradères", "Port-de-Paix", "Môle-Saint-Nicolas",
        "Jean-Rabel", "Jérémie", "Dame-Marie", "Moron"
    ]
    
    // Game rules
    @Published var playerCount: Int = 2
    @Published var humanPlayerCount: Int = 2
    @Published var aiPlayerCount: Int = 0
    @Published var playerConfigurations: [PlayerConfiguration] = []
    @Published var winningScore: Int = 1000
    @Published var handSize: Int = 9
    @Published var playDirection: PlayDirection = .right
    @Published var gameLevel: GameLevel = .pro
    
    // Scoring
    @Published var besiguePoints: Int = 40
    @Published var royalMarriagePoints: Int = 40
    @Published var commonMarriagePoints: Int = 20
    @Published var fourAcesPoints: Int = 100
    @Published var fourKingsPoints: Int = 80
    @Published var fourQueensPoints: Int = 60
    @Published var fourJacksPoints: Int = 40
    @Published var fourJokersPoints: Int = 200
    @Published var sequencePoints: Int = 250
    @Published var trumpFourAcesMultiplier: Int = 2
    @Published var trumpFourKingsMultiplier: Int = 2
    @Published var trumpFourQueensMultiplier: Int = 2
    @Published var trumpFourJacksMultiplier: Int = 2
    @Published var trumpSequenceMultiplier: Int = 1
    @Published var brisqueValue: Int = 10
    @Published var finalTrickBonus: Int = 10
    @Published var trickWithSevenTrumpPoints: Int = 10
    
    // Penalties
    @Published var penalty: Int = -20
    @Published var penaltyBelow100: Int = -20
    @Published var penaltyFewBrisques: Int = -20
    @Published var penaltyOutOfTurn: Int = -20
    @Published var brisqueCutoff: Int = 5
    @Published var minScoreForBrisques: Int = 100
    @Published var minBrisques: Int = 5
    
    // Global card sizes
    @Published var globalCardSize: CardSizeMultiplier = .medium
    
    // Animation timing
    @Published var cardPlayDelay: AnimationTiming = .normal
    @Published var cardPlayDuration: AnimationTiming = .normal
    @Published var dealerDeterminationDelay: Double = 2.0
    @Published var winningCardAnimationDelay: Double = 1.0
    
    // Trick area size
    @Published var trickAreaSize: TrickAreaSize = .medium
    
    // Dealer determination method
    @Published var dealerDeterminationMethod: DealerDeterminationMethod = .random
    
    // Player configuration
    @Published var humanPlayerNames: [String] = ["Player 1", "Player 2"]
    
    // Computed properties
    var useHints: Bool { gameLevel == .novice }
    var aiFerocity: Int { gameLevel == .pro ? 2 : 1 }
    
    // Scoreboard scale
    @Published var scoreboardScale: CGFloat = 1.5 // Controls scoreboard font scaling
    
    // Equatable conformance
    static func == (lhs: GameRules, rhs: GameRules) -> Bool {
        return lhs.playerCount == rhs.playerCount &&
            lhs.winningScore == rhs.winningScore &&
            lhs.handSize == rhs.handSize &&
            lhs.playDirection == rhs.playDirection &&
            lhs.gameLevel == rhs.gameLevel &&
            lhs.besiguePoints == rhs.besiguePoints &&
            lhs.royalMarriagePoints == rhs.royalMarriagePoints &&
            lhs.commonMarriagePoints == rhs.commonMarriagePoints &&
            lhs.fourAcesPoints == rhs.fourAcesPoints &&
            lhs.fourKingsPoints == rhs.fourKingsPoints &&
            lhs.fourQueensPoints == rhs.fourQueensPoints &&
            lhs.fourJacksPoints == rhs.fourJacksPoints &&
            lhs.fourJokersPoints == rhs.fourJokersPoints &&
            lhs.sequencePoints == rhs.sequencePoints &&
            lhs.trumpFourAcesMultiplier == rhs.trumpFourAcesMultiplier &&
            lhs.trumpFourKingsMultiplier == rhs.trumpFourKingsMultiplier &&
            lhs.trumpFourQueensMultiplier == rhs.trumpFourQueensMultiplier &&
            lhs.trumpFourJacksMultiplier == rhs.trumpFourJacksMultiplier &&
            lhs.trumpSequenceMultiplier == rhs.trumpSequenceMultiplier &&
            lhs.brisqueValue == rhs.brisqueValue &&
            lhs.finalTrickBonus == rhs.finalTrickBonus &&
            lhs.trickWithSevenTrumpPoints == rhs.trickWithSevenTrumpPoints &&
            lhs.penalty == rhs.penalty &&
            lhs.penaltyBelow100 == rhs.penaltyBelow100 &&
            lhs.penaltyFewBrisques == rhs.penaltyFewBrisques &&
            lhs.penaltyOutOfTurn == rhs.penaltyOutOfTurn &&
            lhs.brisqueCutoff == rhs.brisqueCutoff &&
            lhs.minScoreForBrisques == rhs.minScoreForBrisques &&
            lhs.minBrisques == rhs.minBrisques &&
            lhs.globalCardSize == rhs.globalCardSize &&
            lhs.cardPlayDelay == rhs.cardPlayDelay &&
            lhs.cardPlayDuration == rhs.cardPlayDuration &&
            lhs.dealerDeterminationDelay == rhs.dealerDeterminationDelay &&
            lhs.winningCardAnimationDelay == rhs.winningCardAnimationDelay &&
            lhs.trickAreaSize == rhs.trickAreaSize &&
            lhs.dealerDeterminationMethod == rhs.dealerDeterminationMethod &&
            lhs.scoreboardScale == rhs.scoreboardScale
    }
    
    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case playerCount, winningScore, handSize, playDirection, gameLevel
        case besiguePoints, royalMarriagePoints, commonMarriagePoints
        case fourAcesPoints, fourKingsPoints, fourQueensPoints, fourJacksPoints, fourJokersPoints, sequencePoints
        case trumpFourAcesMultiplier, trumpFourKingsMultiplier, trumpFourQueensMultiplier, trumpFourJacksMultiplier, trumpSequenceMultiplier
        case brisqueValue, finalTrickBonus, trickWithSevenTrumpPoints
        case penalty, penaltyBelow100, penaltyFewBrisques, penaltyOutOfTurn
        case brisqueCutoff, minScoreForBrisques, minBrisques
        case globalCardSize, cardPlayDelay, cardPlayDuration, dealerDeterminationDelay, winningCardAnimationDelay, trickAreaSize
        case dealerDeterminationMethod, scoreboardScale
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerCount = try container.decode(Int.self, forKey: .playerCount)
        winningScore = try container.decode(Int.self, forKey: .winningScore)
        handSize = try container.decode(Int.self, forKey: .handSize)
        playDirection = try container.decode(PlayDirection.self, forKey: .playDirection)
        gameLevel = try container.decode(GameLevel.self, forKey: .gameLevel)
        besiguePoints = try container.decode(Int.self, forKey: .besiguePoints)
        royalMarriagePoints = try container.decode(Int.self, forKey: .royalMarriagePoints)
        commonMarriagePoints = try container.decode(Int.self, forKey: .commonMarriagePoints)
        fourAcesPoints = try container.decode(Int.self, forKey: .fourAcesPoints)
        fourKingsPoints = try container.decode(Int.self, forKey: .fourKingsPoints)
        fourQueensPoints = try container.decode(Int.self, forKey: .fourQueensPoints)
        fourJacksPoints = try container.decode(Int.self, forKey: .fourJacksPoints)
        fourJokersPoints = try container.decode(Int.self, forKey: .fourJokersPoints)
        sequencePoints = try container.decode(Int.self, forKey: .sequencePoints)
        trumpFourAcesMultiplier = try container.decode(Int.self, forKey: .trumpFourAcesMultiplier)
        trumpFourKingsMultiplier = try container.decode(Int.self, forKey: .trumpFourKingsMultiplier)
        trumpFourQueensMultiplier = try container.decode(Int.self, forKey: .trumpFourQueensMultiplier)
        trumpFourJacksMultiplier = try container.decode(Int.self, forKey: .trumpFourJacksMultiplier)
        trumpSequenceMultiplier = try container.decode(Int.self, forKey: .trumpSequenceMultiplier)
        brisqueValue = try container.decode(Int.self, forKey: .brisqueValue)
        finalTrickBonus = try container.decode(Int.self, forKey: .finalTrickBonus)
        trickWithSevenTrumpPoints = try container.decode(Int.self, forKey: .trickWithSevenTrumpPoints)
        penalty = try container.decode(Int.self, forKey: .penalty)
        penaltyBelow100 = try container.decode(Int.self, forKey: .penaltyBelow100)
        penaltyFewBrisques = try container.decode(Int.self, forKey: .penaltyFewBrisques)
        penaltyOutOfTurn = try container.decode(Int.self, forKey: .penaltyOutOfTurn)
        brisqueCutoff = try container.decode(Int.self, forKey: .brisqueCutoff)
        minScoreForBrisques = try container.decode(Int.self, forKey: .minScoreForBrisques)
        minBrisques = try container.decode(Int.self, forKey: .minBrisques)
        globalCardSize = try container.decode(CardSizeMultiplier.self, forKey: .globalCardSize)
        cardPlayDelay = try container.decode(AnimationTiming.self, forKey: .cardPlayDelay)
        cardPlayDuration = try container.decode(AnimationTiming.self, forKey: .cardPlayDuration)
        dealerDeterminationDelay = try container.decode(Double.self, forKey: .dealerDeterminationDelay)
        winningCardAnimationDelay = try container.decode(Double.self, forKey: .winningCardAnimationDelay)
        trickAreaSize = try container.decode(TrickAreaSize.self, forKey: .trickAreaSize)
        dealerDeterminationMethod = try container.decode(DealerDeterminationMethod.self, forKey: .dealerDeterminationMethod)
        scoreboardScale = try container.decode(CGFloat.self, forKey: .scoreboardScale)
    }
    
    init() {
        // Generate initial player configurations for a default 2-player game
        generatePlayerConfigurations()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playerCount, forKey: .playerCount)
        try container.encode(winningScore, forKey: .winningScore)
        try container.encode(handSize, forKey: .handSize)
        try container.encode(playDirection, forKey: .playDirection)
        try container.encode(gameLevel, forKey: .gameLevel)
        try container.encode(besiguePoints, forKey: .besiguePoints)
        try container.encode(royalMarriagePoints, forKey: .royalMarriagePoints)
        try container.encode(commonMarriagePoints, forKey: .commonMarriagePoints)
        try container.encode(fourAcesPoints, forKey: .fourAcesPoints)
        try container.encode(fourKingsPoints, forKey: .fourKingsPoints)
        try container.encode(fourQueensPoints, forKey: .fourQueensPoints)
        try container.encode(fourJacksPoints, forKey: .fourJacksPoints)
        try container.encode(fourJokersPoints, forKey: .fourJokersPoints)
        try container.encode(sequencePoints, forKey: .sequencePoints)
        try container.encode(trumpFourAcesMultiplier, forKey: .trumpFourAcesMultiplier)
        try container.encode(trumpFourKingsMultiplier, forKey: .trumpFourKingsMultiplier)
        try container.encode(trumpFourQueensMultiplier, forKey: .trumpFourQueensMultiplier)
        try container.encode(trumpFourJacksMultiplier, forKey: .trumpFourJacksMultiplier)
        try container.encode(trumpSequenceMultiplier, forKey: .trumpSequenceMultiplier)
        try container.encode(brisqueValue, forKey: .brisqueValue)
        try container.encode(finalTrickBonus, forKey: .finalTrickBonus)
        try container.encode(trickWithSevenTrumpPoints, forKey: .trickWithSevenTrumpPoints)
        try container.encode(penalty, forKey: .penalty)
        try container.encode(penaltyBelow100, forKey: .penaltyBelow100)
        try container.encode(penaltyFewBrisques, forKey: .penaltyFewBrisques)
        try container.encode(penaltyOutOfTurn, forKey: .penaltyOutOfTurn)
        try container.encode(brisqueCutoff, forKey: .brisqueCutoff)
        try container.encode(minScoreForBrisques, forKey: .minScoreForBrisques)
        try container.encode(minBrisques, forKey: .minBrisques)
        try container.encode(globalCardSize, forKey: .globalCardSize)
        try container.encode(cardPlayDelay, forKey: .cardPlayDelay)
        try container.encode(cardPlayDuration, forKey: .cardPlayDuration)
        try container.encode(dealerDeterminationDelay, forKey: .dealerDeterminationDelay)
        try container.encode(winningCardAnimationDelay, forKey: .winningCardAnimationDelay)
        try container.encode(trickAreaSize, forKey: .trickAreaSize)
        try container.encode(dealerDeterminationMethod, forKey: .dealerDeterminationMethod)
        try container.encode(scoreboardScale, forKey: .scoreboardScale)
    }
    
    // MARK: - Player Configuration Methods
    
    /// Update player count and recalculate AI count
    func updatePlayerCount(_ count: Int) {
        playerCount = count
        humanPlayerCount = min(humanPlayerCount, count)
        aiPlayerCount = count - humanPlayerCount
        generatePlayerConfigurations()
    }
    
    /// Update human player count and recalculate AI count
    func updateHumanPlayerCount(_ count: Int) {
        humanPlayerCount = min(count, playerCount)
        aiPlayerCount = playerCount - humanPlayerCount
        generatePlayerConfigurations()
    }
    
    /// Generate player configurations with proper seating
    func generatePlayerConfigurations() {
        var configs: [PlayerConfiguration] = []
        var usedCities: Set<String> = []
        
        // Create human players first
        for i in 0..<humanPlayerCount {
            let name = humanPlayerNames.indices.contains(i) ? humanPlayerNames[i] : "Player \(i + 1)"
            let config = PlayerConfiguration(name: name, type: .human, position: i)
            configs.append(config)
        }
        
        // Create AI players
        for i in 0..<aiPlayerCount {
            let aiName = generateAIName(excluding: usedCities)
            usedCities.insert(aiName)
            let config = PlayerConfiguration(name: aiName, type: .ai, position: humanPlayerCount + i)
            configs.append(config)
        }
        
        // Optimize seating to avoid consecutive humans where possible
        configs = optimizeSeating(configs)
        
        playerConfigurations = configs
        print("🎮 Generated \(configs.count) player configurations")
    }
    
    /// Update human player name at specific position
    func updateHumanPlayerName(at position: Int, name: String) {
        if let index = playerConfigurations.firstIndex(where: { $0.position == position && $0.type == .human }) {
            playerConfigurations[index].name = name.isEmpty ? "Player \(position + 1)" : name
        }
    }
    
    /// Generate AI name from Haitian cities
    private func generateAIName(excluding usedCities: Set<String>) -> String {
        let availableCities = GameRules.haitianCities.filter { !usedCities.contains($0) }
        let city = availableCities.randomElement() ?? "Port-au-Prince"
        return "\(city) (AI)"
    }
    
    /// Optimize seating to avoid consecutive humans where possible
    private func optimizeSeating(_ configs: [PlayerConfiguration]) -> [PlayerConfiguration] {
        var optimized = configs
        
        // For 2 players: Human, AI
        if configs.count == 2 {
            let humans = configs.filter { $0.type == .human }
            let ais = configs.filter { $0.type == .ai }
            if humans.count == 1 && ais.count == 1 {
                optimized[0].position = 0 // Human
                optimized[1].position = 1 // AI
            }
        }
        // For 3 players: Human, AI, Human (if 2 humans) or Human, AI, AI (if 1 human)
        else if configs.count == 3 {
            let humans = configs.filter { $0.type == .human }
            let ais = configs.filter { $0.type == .ai }
            
            if humans.count == 2 && ais.count == 1 {
                // Human, AI, Human
                optimized[0].position = 0 // Human
                optimized[1].position = 1 // AI
                optimized[2].position = 2 // Human
            } else if humans.count == 1 && ais.count == 2 {
                // Human, AI, AI
                optimized[0].position = 0 // Human
                optimized[1].position = 1 // AI
                optimized[2].position = 2 // AI
            }
        }
        // For 4 players: Human, AI, Human, AI (if 2 humans) or Human, AI, AI, AI (if 1 human) or Human, AI, Human, Human (if 3 humans)
        else if configs.count == 4 {
            let humans = configs.filter { $0.type == .human }
            let ais = configs.filter { $0.type == .ai }
            
            if humans.count == 2 && ais.count == 2 {
                // Human, AI, Human, AI
                optimized[0].position = 0 // Human
                optimized[1].position = 1 // AI
                optimized[2].position = 2 // Human
                optimized[3].position = 3 // AI
            } else if humans.count == 1 && ais.count == 3 {
                // Human, AI, AI, AI
                optimized[0].position = 0 // Human
                optimized[1].position = 1 // AI
                optimized[2].position = 2 // AI
                optimized[3].position = 3 // AI
            } else if humans.count == 3 && ais.count == 1 {
                // Human, AI, Human, Human
                optimized[0].position = 0 // Human
                optimized[1].position = 1 // AI
                optimized[2].position = 2 // Human
                optimized[3].position = 3 // Human
            }
        }
        
        return optimized
    }
    
    /// Validate player configuration
    func validateConfiguration() -> Bool {
        return playerConfigurations.count == playerCount &&
               playerConfigurations.filter { $0.type == .human }.count == humanPlayerCount &&
               playerConfigurations.filter { $0.type == .ai }.count == aiPlayerCount &&
               playerConfigurations.allSatisfy { $0.position >= 0 && $0.position < playerCount }
    }
} 