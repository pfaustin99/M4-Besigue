import Foundation

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