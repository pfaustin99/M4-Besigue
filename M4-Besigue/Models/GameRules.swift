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

/// GameRules holds game settings that affect all future games
class GameRules: ObservableObject, Codable, Equatable {
    // TODO: After gameplay is complete, revisit and improve the 'draw jacks' dealer determination logic and UI as discussed with the user.
    
    // Game rules
    @Published var playerCount: Int = 2
    @Published var winningScore: Int = 1000
    @Published var handSize: Int = 9
    @Published var playDirection: PlayDirection = .right
    @Published var gameLevel: GameLevel = .novice
    
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
    
    // Computed properties
    var useHints: Bool { gameLevel == .novice }
    var aiFerocity: Int { gameLevel == .pro ? 2 : 1 }
    
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
            lhs.dealerDeterminationMethod == rhs.dealerDeterminationMethod
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
        case dealerDeterminationMethod
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
    }
    
    init() {
        // Use default values
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
    }
} 