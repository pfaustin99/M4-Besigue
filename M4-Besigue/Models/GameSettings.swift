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
struct GameSettings: Codable, Equatable {
    // Scoring
    var besiguePoints: Int = 40
    var royalMarriagePoints: Int = 40
    var commonMarriagePoints: Int = 20
    var fourAcesPoints: Int = 100
    var fourKingsPoints: Int = 80
    var fourQueensPoints: Int = 60
    var fourJacksPoints: Int = 40
    var fourJokersPoints: Int = 200
    var sequencePoints: Int = 250
    var trumpFourAcesMultiplier: Int = 2
    var trumpFourKingsMultiplier: Int = 2
    var trumpFourQueensMultiplier: Int = 2
    var trumpFourJacksMultiplier: Int = 2
    var trumpSequenceMultiplier: Int = 1 // Sequence is always trump
    var brisquePoints: Int = 10 // For each Ace or 10 in tricks
    var trickWithSevenTrumpPoints: Int = 10
    var finalTrickPoints: Int = 10

    // Penalties
    var penaltyBelow100: Int = -20
    var penaltyFewBrisques: Int = -20
    var penaltyOutOfTurn: Int = -20 // Optional, may not be enforced
    var minBrisques: Int = 5

    // Game rules
    var playDirection: PlayDirection = .right
    var gameLevel: GameLevel = .novice
    var handSize: Int = 9
    var numPlayers: Int = 2 // Can be 2, 3, or 4
    var useHints: Bool { gameLevel == .novice }
    var aiFerocity: Int { gameLevel == .pro ? 2 : 1 } // 1 = easy, 2 = hard

    // Add more settings as needed
}

struct MeldBadgeIcons {
    var fourKings: String = "👑" // African king with crown
    var fourQueens: String = "👸" // African queen with crown
    var fourJacks: String = "🏜️" // Nomad
    var fourJokers: String = "🤡" // Jester
    var royalMarriage: String = "👑"
    var commonMarriage: String = "💍"
    var besigue: String = "🅱️"
    var sequence: [Suit: String] = [
        .hearts: "♥️",
        .spades: "♠️",
        .diamonds: "♦️",
        .clubs: "♣️"
    ]
    var exhausted: String = "❌"
}

class GameSettings: ObservableObject {
    @Published var minBrisques: Int
    @Published var minScoreForBrisques: Int
    @Published var brisqueValue: Int
    @Published var penalty: Int
    @Published var brisqueCutoff: Int
    @Published var winningScore: Int
    @Published var finalTrickBonus: Int
    @Published var hintsEnabled: Bool = true
    @Published var badgeIcons: MeldBadgeIcons = MeldBadgeIcons()
    
    init(playerCount: Int) {
        self.minBrisques = 5
        self.minScoreForBrisques = 100
        self.brisqueValue = 10
        self.penalty = -20
        self.brisqueCutoff = 600
        self.winningScore = playerCount == 2 ? 1000 : 750
        self.finalTrickBonus = 10
    }
} 