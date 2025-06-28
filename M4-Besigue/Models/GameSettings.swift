import Foundation

/// Enum for play direction
enum PlayDirection: String, CaseIterable, Codable {
    case right  // Counterclockwise (default)
    case left   // Clockwise
}

/// Enum for game level
enum GameLevel: String, CaseIterable, Codable {
    case novice
    case pro
}

/// GameSettings holds all configurable values for scoring, penalties, and rules
class GameSettings: ObservableObject, Codable, Equatable {
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
    @Published var trumpSequenceMultiplier: Int = 1 // Sequence is always trump
    @Published var brisqueValue: Int = 10 // Points per brisque (Ace or 10)
    @Published var finalTrickBonus: Int = 10 // Points for winning the last trick
    @Published var penalty: Int = -20 // General penalty value
    @Published var brisqueCutoff: Int = 5 // Minimum brisques to avoid penalty
    @Published var minScoreForBrisques: Int = 100 // Minimum score to avoid penalty
    @Published var winningScore: Int = 1000 // Score to win the game
    @Published var trickWithSevenTrumpPoints: Int = 10
    @Published var finalTrickPoints: Int = 10

    // Penalties
    @Published var penaltyBelow100: Int = -20
    @Published var penaltyFewBrisques: Int = -20
    @Published var penaltyOutOfTurn: Int = -20 // Optional, may not be enforced
    @Published var minBrisques: Int = 5

    // Game rules
    @Published var playDirection: PlayDirection = .right
    @Published var gameLevel: GameLevel = .novice
    @Published var handSize: Int = 9
    @Published var numPlayers: Int = 2 // Can be 2, 3, or 4
    @Published var playerCount: Int = 2
    var useHints: Bool { gameLevel == .novice }
    var aiFerocity: Int { gameLevel == .pro ? 2 : 1 } // 1 = easy, 2 = hard

    // Badge Icons
    @Published var badgeIcons: MeldBadgeIcons = MeldBadgeIcons()

    // Equatable conformance
    static func == (lhs: GameSettings, rhs: GameSettings) -> Bool {
        return lhs.besiguePoints == rhs.besiguePoints &&
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
            lhs.penalty == rhs.penalty &&
            lhs.brisqueCutoff == rhs.brisqueCutoff &&
            lhs.minScoreForBrisques == rhs.minScoreForBrisques &&
            lhs.winningScore == rhs.winningScore &&
            lhs.trickWithSevenTrumpPoints == rhs.trickWithSevenTrumpPoints &&
            lhs.finalTrickPoints == rhs.finalTrickPoints &&
            lhs.penaltyBelow100 == rhs.penaltyBelow100 &&
            lhs.penaltyFewBrisques == rhs.penaltyFewBrisques &&
            lhs.penaltyOutOfTurn == rhs.penaltyOutOfTurn &&
            lhs.minBrisques == rhs.minBrisques &&
            lhs.playDirection == rhs.playDirection &&
            lhs.gameLevel == rhs.gameLevel &&
            lhs.handSize == rhs.handSize &&
            lhs.numPlayers == rhs.numPlayers &&
            lhs.playerCount == rhs.playerCount &&
            lhs.badgeIcons == rhs.badgeIcons
    }

    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case besiguePoints, royalMarriagePoints, commonMarriagePoints, fourAcesPoints, fourKingsPoints, fourQueensPoints, fourJacksPoints, fourJokersPoints, sequencePoints, trumpFourAcesMultiplier, trumpFourKingsMultiplier, trumpFourQueensMultiplier, trumpFourJacksMultiplier, trumpSequenceMultiplier, brisqueValue, finalTrickBonus, penalty, brisqueCutoff, minScoreForBrisques, winningScore, trickWithSevenTrumpPoints, finalTrickPoints, penaltyBelow100, penaltyFewBrisques, penaltyOutOfTurn, minBrisques, playerCount, playDirection, gameLevel, handSize, numPlayers, badgeIcons
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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
        penalty = try container.decode(Int.self, forKey: .penalty)
        brisqueCutoff = try container.decode(Int.self, forKey: .brisqueCutoff)
        minScoreForBrisques = try container.decode(Int.self, forKey: .minScoreForBrisques)
        winningScore = try container.decode(Int.self, forKey: .winningScore)
        trickWithSevenTrumpPoints = try container.decode(Int.self, forKey: .trickWithSevenTrumpPoints)
        finalTrickPoints = try container.decode(Int.self, forKey: .finalTrickPoints)
        penaltyBelow100 = try container.decode(Int.self, forKey: .penaltyBelow100)
        penaltyFewBrisques = try container.decode(Int.self, forKey: .penaltyFewBrisques)
        penaltyOutOfTurn = try container.decode(Int.self, forKey: .penaltyOutOfTurn)
        minBrisques = try container.decode(Int.self, forKey: .minBrisques)
        playerCount = try container.decode(Int.self, forKey: .playerCount)
        playDirection = try container.decode(PlayDirection.self, forKey: .playDirection)
        gameLevel = try container.decode(GameLevel.self, forKey: .gameLevel)
        handSize = try container.decode(Int.self, forKey: .handSize)
        numPlayers = try container.decode(Int.self, forKey: .numPlayers)
        badgeIcons = try container.decode(MeldBadgeIcons.self, forKey: .badgeIcons)
    }

    init(playerCount: Int = 2) {
        self.playerCount = playerCount
    }

    init() {}

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
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
        try container.encode(penalty, forKey: .penalty)
        try container.encode(brisqueCutoff, forKey: .brisqueCutoff)
        try container.encode(minScoreForBrisques, forKey: .minScoreForBrisques)
        try container.encode(winningScore, forKey: .winningScore)
        try container.encode(trickWithSevenTrumpPoints, forKey: .trickWithSevenTrumpPoints)
        try container.encode(finalTrickPoints, forKey: .finalTrickPoints)
        try container.encode(penaltyBelow100, forKey: .penaltyBelow100)
        try container.encode(penaltyFewBrisques, forKey: .penaltyFewBrisques)
        try container.encode(penaltyOutOfTurn, forKey: .penaltyOutOfTurn)
        try container.encode(minBrisques, forKey: .minBrisques)
        try container.encode(playerCount, forKey: .playerCount)
        try container.encode(playDirection, forKey: .playDirection)
        try container.encode(gameLevel, forKey: .gameLevel)
        try container.encode(handSize, forKey: .handSize)
        try container.encode(numPlayers, forKey: .numPlayers)
        try container.encode(badgeIcons, forKey: .badgeIcons)
    }
}

struct MeldBadgeIcons: Codable, Equatable {
    var fourKings: String = "👑"
    var fourQueens: String = "👸"
    var fourJacks: String = "🃏"
    var fourAces: String = "🅰️"
    var fourJokers: String = "🃏🃏"
    var royalMarriage: String = "💍"
    var commonMarriage: String = "💑"
    var besigue: String = "♠️Q♦️J"
    var sequence: String = "🔗"
} 