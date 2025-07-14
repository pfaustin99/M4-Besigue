import Foundation

// MARK: - AI Service
class AIService: ObservableObject {
    
    // MARK: - AI Difficulty Levels
    enum Difficulty {
        case easy
        case medium
        case hard
        case expert
    }
    
    private let difficulty: Difficulty
    
    init(difficulty: Difficulty = .medium) {
        self.difficulty = difficulty
    }
    
    // MARK: - Main AI Decision Methods
    
    /// Determine which melds to declare
    func decideMeldsToDeclare(for player: Player, in game: Game) -> [Meld] {
        // No melds allowed in endgame
        if game.isEndgame {
            return []
        }
        
        let possibleMelds = game.getPossibleMelds(for: player)
        var meldsToDeclare: [Meld] = []
        
        // If trump is not set, AI must decide on a marriage to declare.
        if game.trumpSuit == nil {
            let marriages = possibleMelds.filter { $0.type == .commonMarriage }
            if !marriages.isEmpty {
                // Find the best marriage to declare to set the trump suit.
                var bestMarriage: Meld?
                var maxSuitStrength = -1
                
                for marriage in marriages {
                    guard let suit = marriage.cardIDs.compactMap({ player.cardByID($0)?.suit }).first else { continue }
                    let strength = calculateSuitStrength(cards: player.cardsOfSuit(suit), suit: suit)
                    if strength > maxSuitStrength {
                        maxSuitStrength = strength
                        bestMarriage = marriage
                    }
                }
                
                if let marriageToDeclare = bestMarriage {
                    return [marriageToDeclare]
                }
            }
        }
        
        // Always declare Bésigue if available (highest priority)
        if let besigue = possibleMelds.first(where: { $0.type == .besigue }) {
            meldsToDeclare.append(besigue)
        }
        
        // Declare high-value melds first
        let highValueMelds = possibleMelds.filter { $0.pointValue >= 60 }
        meldsToDeclare.append(contentsOf: highValueMelds)
        
        // For medium difficulty and above, be more strategic about melds
        if difficulty != .easy {
            // Consider trump marriages more valuable
            let trumpMarriages = possibleMelds.filter { 
                $0.type == .royalMarriage && 
                $0.cardIDs.compactMap { player.cardByID($0)?.suit }.first == game.trumpSuit 
            }
            meldsToDeclare.append(contentsOf: trumpMarriages)
            
            // Consider common marriages if we have good trump cards
            let commonMarriages = possibleMelds.filter { $0.type == .commonMarriage }
            if hasStrongTrumpCards(player: player, trumpSuit: game.trumpSuit) {
                meldsToDeclare.append(contentsOf: commonMarriages)
            }
        }
        
        return meldsToDeclare
    }
    
    /// Choose which card to play
    func chooseCardToPlay(for player: Player, in game: Game) -> PlayerCard? {
        let playableCards = game.getPlayableCards()
        
        print("🤖 AI choosing card to play:")
        print("   Lead suit: \(game.currentTrick.first?.suit?.rawValue ?? "None")")
        print("   Trump suit: \(game.trumpSuit?.rawValue ?? "None")")
        print("   Playable cards: \(playableCards.map { $0.displayName })")
        
        guard !playableCards.isEmpty else { return nil }
        
        switch game.currentPhase {
        case .playing, .endgame:
            return chooseCardForTrick(player: player, game: game, playableCards: playableCards)
        default:
            return playableCards.randomElement()
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Calculate the strength of a suit based on cards held
    private func calculateSuitStrength(cards: [PlayerCard], suit: Suit) -> Int {
        var score = 0
        
        for card in cards {
            switch card.value {
            case .ace:
                score += 8
            case .ten:
                score += 7
            case .king:
                score += 6
            case .queen:
                score += 5
            case .jack:
                score += 4
            case .nine:
                score += 3
            case .eight:
                score += 2
            case .seven:
                score += 1
            case .none:
                // Joker cards - give them a high value
                score += 9
            }
        }
        
        // Bonus for having many cards of this suit
        score += cards.count * 2
        
        return score
    }
    
    /// Check if player has strong trump cards
    private func hasStrongTrumpCards(player: Player, trumpSuit: Suit?) -> Bool {
        guard let trumpSuit = trumpSuit else { return false }
        
        let trumpCards = player.cardsOfSuit(trumpSuit)
        let highTrumpCards = trumpCards.filter { 
            [.ace, .ten, .king, .queen, .jack].contains($0.value) 
        }
        
        return highTrumpCards.count >= 2
    }
    
    /// Choose card to play in a trick
    private func chooseCardForTrick(player: Player, game: Game, playableCards: [PlayerCard]) -> PlayerCard {
        let isLeading = game.currentTrick.isEmpty
        let leadSuit = game.currentTrick.first?.suit
        let trumpSuit = game.trumpSuit
        
        if isLeading {
            return chooseLeadCard(player: player, game: game, playableCards: playableCards)
        } else {
            return chooseFollowCard(player: player, game: game, playableCards: playableCards, leadSuit: leadSuit, trumpSuit: trumpSuit)
        }
    }
    
    /// Choose card when leading the trick
    private func chooseLeadCard(player: Player, game: Game, playableCards: [PlayerCard]) -> PlayerCard {
        // Sort cards by value (highest first)
        let sortedCards = playableCards.sorted { card1, card2 in
            card1.rank > card2.rank
        }
        
        // Lead with highest card if we have good trump protection
        if hasStrongTrumpCards(player: player, trumpSuit: game.trumpSuit) {
            return sortedCards.first ?? playableCards.first!
        }
        
        // Lead with middle-strength card to avoid overcommitting
        let middleIndex = sortedCards.count / 2
        return sortedCards[middleIndex]
    }
    
    /// Choose card when following to a trick
    private func chooseFollowCard(player: Player, game: Game, playableCards: [PlayerCard], leadSuit: Suit?, trumpSuit: Suit?) -> PlayerCard {
        guard let leadSuit = leadSuit else { return playableCards.first! }
        
        let currentWinningCard = findCurrentWinningCard(game: game, leadSuit: leadSuit, trumpSuit: trumpSuit)
        
        // Try to win the trick if possible
        if let winningCard = findWinningCard(playableCards: playableCards, currentWinner: currentWinningCard, leadSuit: leadSuit, trumpSuit: trumpSuit) {
            return winningCard
        }
        
        // If we can't win, play lowest card to conserve high cards
        let sortedCards = playableCards.sorted { card1, card2 in
            card1.rank < card2.rank
        }
        
        return sortedCards.first ?? playableCards.first!
    }
    
    /// Find the current winning card in the trick
    private func findCurrentWinningCard(game: Game, leadSuit: Suit, trumpSuit: Suit?) -> PlayerCard? {
        guard !game.currentTrick.isEmpty else { return nil }
        
        var winningCard = game.currentTrick[0]
        
        for card in game.currentTrick {
            if card.canBeat(winningCard, trumpSuit: trumpSuit, leadSuit: leadSuit) {
                winningCard = card
            }
        }
        
        return winningCard
    }
    
    /// Find a card that can win the current trick
    private func findWinningCard(playableCards: [PlayerCard], currentWinner: PlayerCard?, leadSuit: Suit, trumpSuit: Suit?) -> PlayerCard? {
        guard let currentWinner = currentWinner else { return playableCards.first }
        
        for card in playableCards {
            if card.canBeat(currentWinner, trumpSuit: trumpSuit, leadSuit: leadSuit) {
                return card
            }
        }
        
        return nil
    }
    
    /// Evaluate hand strength for strategic decisions
    private func evaluateHandStrength(player: Player, game: Game) -> Int {
        var score = 0
        
        // Count high cards
        let highCards = player.hand.filter { 
            [.ace, .ten, .king, .queen, .jack].contains($0.value) 
        }
        score += highCards.count * 10
        
        // Bonus for trump cards
        if let trumpSuit = game.trumpSuit {
            let trumpCards = player.cardsOfSuit(trumpSuit)
            score += trumpCards.count * 5
        }
        
        // Bonus for long suits
        for suit in Suit.allCases {
            let cardsOfSuit = player.cardsOfSuit(suit)
            if cardsOfSuit.count >= 4 {
                score += cardsOfSuit.count * 2
            }
        }
        
        return score
    }
    
    /// Determine if we should try to win the trick
    private func shouldTryToWin(player: Player, game: Game) -> Bool {
        let handStrength = evaluateHandStrength(player: player, game: game)
        let cardsRemaining = player.hand.count
        
        // More aggressive with strong hands and fewer cards
        if handStrength > 50 && cardsRemaining <= 5 {
            return true
        }
        
        // More conservative with weak hands or many cards
        if handStrength < 30 || cardsRemaining > 7 {
            return false
        }
        
        // Medium difficulty decision
        return difficulty != .easy
    }
}

// MARK: - AI Player Extension
extension Player {
    /// Make AI decisions for this player
    func makeAIDecision(in game: Game, aiService: AIService) {
        guard type == .ai else { return }
        
        // Handle melding if allowed (when AI wins a trick)
        if game.canPlayerMeld {
            let meldsToDeclare = aiService.decideMeldsToDeclare(for: self, in: game)
            for meld in meldsToDeclare {
                game.declareMeld(meld, by: self)
            }
            
            // Select trump if not already selected
            if game.trumpSuit == nil {
                // The decision to declare a marriage to set the trump
                // is now handled within decideMeldsToDeclare.
            }
        }
        
        // Handle card playing in playing or endgame phases
        if game.currentPhase == .playing || game.currentPhase == .endgame {
            if let cardToPlay = aiService.chooseCardToPlay(for: self, in: game) {
                game.playCard(cardToPlay, from: self)
            }
        }
    }
} 