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
    
    // MARK: - Card Memory
    struct CardMemory {
        private(set) var playedCards: [PlayerCard] = []
        private(set) var meldedCards: [PlayerCard] = []

        mutating func addPlayedCard(_ card: PlayerCard) {
            if !playedCards.contains(where: { $0.id == card.id }) {
                playedCards.append(card)
            }
        }
        mutating func addMeldedCards(_ cards: [PlayerCard]) {
            for card in cards {
                if !meldedCards.contains(where: { $0.id == card.id }) {
                    meldedCards.append(card)
                }
            }
        }
        func isCardPlayed(_ card: PlayerCard) -> Bool {
            playedCards.contains(where: { $0.id == card.id })
        }
        func isCardMelded(_ card: PlayerCard) -> Bool {
            meldedCards.contains(where: { $0.id == card.id })
        }
        func knownCards() -> [PlayerCard] {
            playedCards + meldedCards
        }
        // --- AI Inference additions ---
        /// Returns all cards not seen in play, melds, or any player's hand
        func unaccountedForCards(allPlayers: [Player], deck: Deck) -> [PlayerCard] {
            // Gather all cards that are accounted for: played, melded, in hands
            var accountedFor = Set<UUID>()
            for card in playedCards + meldedCards {
                accountedFor.insert(card.id)
            }
            for player in allPlayers {
                for card in player.hand {
                    accountedFor.insert(card.id)
                }
            }
            
            // The full deck (including jokers and discard pile)
            let allCards = deck.cards + deck.discardPile
            
            // Return cards in the full deck that are NOT accounted for
            return allCards.filter { !accountedFor.contains($0.id) }.map { PlayerCard(card: $0) }
        }
        /// Returns a dictionary mapping opponent player IDs to the set of cards that could be in their hand (not seen elsewhere)
        func inferOpponentHands(allPlayers: [Player], selfPlayer: Player, deck: Deck) -> [UUID: [PlayerCard]] {
            // For each opponent, return cards not seen in play, melds, or in any hand except possibly theirs
            var result: [UUID: [PlayerCard]] = [:]
            
            // Gather all cards that are accounted for: played, melded, in hands
            var accountedFor = Set<UUID>()
            for card in playedCards + meldedCards {
                accountedFor.insert(card.id)
            }
            for player in allPlayers {
                for card in player.hand {
                    accountedFor.insert(card.id)
                }
            }
            
            let allCards = deck.cards + deck.discardPile
            let unaccounted = allCards.filter { !accountedFor.contains($0.id) }.map { PlayerCard(card: $0) }
            
            for player in allPlayers where player.id != selfPlayer.id {
                // For now, just assign all unaccounted cards as possible for each opponent
                result[player.id] = unaccounted
            }
            return result
        }
        #if DEBUG
        mutating func test_setPlayedCards(_ cards: [PlayerCard]) {
            self.playedCards = cards
        }
        #endif
    }
    
    var cardMemory = CardMemory()
    
    // MARK: - Advanced Trick-Taking Inference
    // Track which suits each opponent is void in (endgame only)
    var opponentVoidSuits: [UUID: Set<Suit>] = [:]
    // Track if AI should lead with a joker after melding
    var jokerToLead: PlayerCard? = nil

    // Helper: Track known trump cards (played, melded, in hand)
    private func knownTrumpCards(trumpSuit: Suit?, allPlayers: [Player]) -> Set<UUID> {
        guard let trumpSuit = trumpSuit else { return [] }
        var known: Set<UUID> = []
        // Played
        known.formUnion(cardMemory.playedCards.filter { $0.suit == trumpSuit }.map { $0.id })
        // Melded
        known.formUnion(cardMemory.meldedCards.filter { $0.suit == trumpSuit }.map { $0.id })
        // In all hands
        for player in allPlayers {
            known.formUnion(player.hand.filter { $0.suit == trumpSuit }.map { $0.id })
        }
        return known
    }
    // Helper: Are opponents likely out of trump?
    func opponentsLikelyOutOfTrump(trumpSuit: Suit?, allPlayers: [Player], selfPlayer: Player) -> Bool {
        guard let trumpSuit = trumpSuit else { 
            print("🔍 AI DEBUG: No trump suit set")
            return false 
        }
        
        print("🔍 AI DEBUG: Checking if opponents are out of trump suit: \(trumpSuit.rawValue)")
        
        // Count how many of each trump card type we've seen
        var trumpCounts: [CardValue: Int] = [:]
        
        // Initialize counts for all trump card types (4 of each)
        for value in CardValue.allCases {
            trumpCounts[value] = 4
        }
        print("🔍 AI DEBUG: Initial trump counts: \(trumpCounts)")
        
        // Subtract played trump cards
        let playedTrumpCards = cardMemory.playedCards.filter { $0.suit == trumpSuit }
        print("🔍 AI DEBUG: Played trump cards: \(playedTrumpCards.map { $0.displayName })")
        for card in playedTrumpCards {
            if let value = card.value {
                trumpCounts[value, default: 0] -= 1
                print("🔍 AI DEBUG: Subtracted played \(card.displayName), remaining \(value.rawValue): \(trumpCounts[value] ?? 0)")
            }
        }
        
        // Subtract melded trump cards
        let meldedTrumpCards = cardMemory.meldedCards.filter { $0.suit == trumpSuit }
        print("🔍 AI DEBUG: Melded trump cards: \(meldedTrumpCards.map { $0.displayName })")
        for card in meldedTrumpCards {
            if let value = card.value {
                trumpCounts[value, default: 0] -= 1
                print("🔍 AI DEBUG: Subtracted melded \(card.displayName), remaining \(value.rawValue): \(trumpCounts[value] ?? 0)")
            }
        }
        
        // Subtract trump cards in all hands
        for player in allPlayers {
            let playerTrumpCards = player.held.filter { $0.suit == trumpSuit }
            print("🔍 AI DEBUG: \(player.type.rawValue) trump cards: \(playerTrumpCards.map { $0.displayName })")
            for card in playerTrumpCards {
                if let value = card.value {
                    trumpCounts[value, default: 0] -= 1
                    print("🔍 AI DEBUG: Subtracted \(player.type.rawValue) \(card.displayName), remaining \(value.rawValue): \(trumpCounts[value] ?? 0)")
                }
            }
        }
        
        print("🔍 AI DEBUG: Final trump counts: \(trumpCounts)")
        let opponentsOut = trumpCounts.values.allSatisfy { $0 <= 0 }
        print("🔍 AI DEBUG: Opponents out of trump: \(opponentsOut)")
        
        // If all remaining counts are 0 or negative, opponents are out of trump
        return opponentsOut
    }
    // Update void suits (endgame only)
    func updateVoidSuitsIfEndgame(game: Game, player: Player, leadSuit: Suit, playedCard: PlayerCard) {
        if game.isEndgame && playedCard.suit != leadSuit {
            opponentVoidSuits[player.id, default: []].insert(leadSuit)
        }
    }
    // After melding with a joker, set jokerToLead
    func afterMeld(meld: Meld, by player: Player) {
        if let joker = meld.cardIDs.compactMap({ player.cardByID($0) }).first(where: { $0.isJoker }) {
            jokerToLead = joker
        }
    }
    // --- AI Decision Methods (update chooseCardForTrick/chooseLeadCard) ---
    private func chooseCardForTrick(player: Player, game: Game, playableCards: [PlayerCard]) -> PlayerCard {
        let isLeading = game.currentTrick.isEmpty
        let leadSuit = game.currentTrick.first?.suit
        let trumpSuit = game.trumpSuit
        let allPlayers = game.players
        
        print("🔍 AI DEBUG: chooseCardForTrick - isLeading: \(isLeading), leadSuit: \(leadSuit?.rawValue ?? "nil"), trumpSuit: \(trumpSuit?.rawValue ?? "nil")")
        print("🔍 AI DEBUG: Available playable cards: \(playableCards.map { $0.displayName })")
        
        // --- ENDGAME RULES ---
        if game.isEndgame {
            print("🔍 AI DEBUG: ENDGAME MODE - Applying strict endgame rules")
            
            // Joker lead logic (endgame priority)
            if isLeading, let joker = jokerToLead, playableCards.contains(joker) {
                print("🔍 AI DEBUG: Leading with joker after meld: \(joker.displayName)")
                jokerToLead = nil
                return joker
            }
            
            // Check if AI should lead with a Joker strategically
            if isLeading {
                let jokers = playableCards.filter { $0.isJoker }
                if !jokers.isEmpty {
                    let shouldLeadJoker = shouldLeadWithJokerInEndgame(player: player, game: game, playableCards: playableCards)
                    if shouldLeadJoker {
                        let chosenJoker = jokers.first!
                        print("🔍 AI DEBUG: Leading with joker strategically: \(chosenJoker.displayName)")
                        return chosenJoker
                    }
                }
            }
            
            // Handle Joker follow (endgame)
            if !isLeading, let leadCard = game.currentTrick.first, leadCard.isJoker {
                return handleJokerFollowInEndgame(player: player, game: game, playableCards: playableCards, trumpSuit: trumpSuit)
            }
            
            // Strict trick-taking rules for endgame
            if isLeading {
                return chooseLeadCardEndgame(player: player, game: game, playableCards: playableCards)
            } else {
                return chooseFollowCardEndgame(player: player, game: game, playableCards: playableCards, leadSuit: leadSuit, trumpSuit: trumpSuit)
            }
        }
        
        // --- NORMAL GAME LOGIC (non-endgame) ---
        
        // Joker lead logic (after meld)
        if isLeading, let joker = jokerToLead, playableCards.contains(joker) {
            print("🔍 AI DEBUG: Leading with joker after meld: \(joker.displayName)")
            jokerToLead = nil
            return joker
        }
        
        // --- MELD AWARENESS ---
        let possibleMelds = game.getPossibleMelds(for: player)
        let meldCardIDs = Set(possibleMelds.flatMap { $0.cardIDs })
        print("🔍 AI DEBUG: Possible melds: \(possibleMelds.map { $0.type.rawValue })")
        print("🔍 AI DEBUG: Meld card IDs: \(meldCardIDs)")
        
        // In endgame, if opponents are out of trump, allow brisque cards to be played
        let allowBrisqueInEndgame = game.isEndgame && opponentsLikelyOutOfTrump(trumpSuit: trumpSuit, allPlayers: allPlayers, selfPlayer: player)
        print("🔍 AI DEBUG: Allow brisque in endgame: \(allowBrisqueInEndgame)")
        
        func safePlayableCards(_ candidates: [PlayerCard]) -> [PlayerCard] {
            // If in endgame and opponents are out of trump, allow brisque cards
            if allowBrisqueInEndgame {
                let safe = candidates.filter { !meldCardIDs.contains($0.id) }
                if !safe.isEmpty { 
                    print("🔍 AI DEBUG: Safe cards (endgame, no meld): \(safe.map { $0.displayName })")
                    return safe 
                }
                let notMeld = candidates.filter { !meldCardIDs.contains($0.id) }
                if !notMeld.isEmpty { 
                    print("🔍 AI DEBUG: Not meld cards: \(notMeld.map { $0.displayName })")
                    return notMeld 
                }
                print("🔍 AI DEBUG: Using all candidates: \(candidates.map { $0.displayName })")
                return candidates
            } else {
                // Normal filtering: avoid meld and brisque cards
                let safe = candidates.filter { !meldCardIDs.contains($0.id) && !$0.isBrisque }
                if !safe.isEmpty { 
                    print("🔍 AI DEBUG: Safe cards (normal): \(safe.map { $0.displayName })")
                    return safe 
                }
                let notMeld = candidates.filter { !meldCardIDs.contains($0.id) }
                if !notMeld.isEmpty { 
                    print("🔍 AI DEBUG: Not meld cards: \(notMeld.map { $0.displayName })")
                    return notMeld 
                }
                let notBrisque = candidates.filter { !$0.isBrisque }
                if !notBrisque.isEmpty { 
                    print("🔍 AI DEBUG: Not brisque cards: \(notBrisque.map { $0.displayName })")
                    return notBrisque 
                }
                print("🔍 AI DEBUG: Using all candidates: \(candidates.map { $0.displayName })")
                return candidates
            }
        }
        
        let finalPlayableCards = safePlayableCards(playableCards)
        print("🔍 AI DEBUG: Final playable cards: \(finalPlayableCards.map { $0.displayName })")
        
        if isLeading {
            let chosenCard = chooseLeadCard(player: player, game: game, playableCards: finalPlayableCards, meldCardIDs: meldCardIDs)
            print("🔍 AI DEBUG: Chose lead card: \(chosenCard.displayName)")
            return chosenCard
        } else {
            let chosenCard = chooseFollowCard(player: player, game: game, playableCards: finalPlayableCards, leadSuit: leadSuit, trumpSuit: trumpSuit, meldCardIDs: meldCardIDs)
            print("🔍 AI DEBUG: Chose follow card: \(chosenCard.displayName)")
            return chosenCard
        }
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
    
    /// Enhanced lead card selection
    private func chooseLeadCard(player: Player, game: Game, playableCards: [PlayerCard], meldCardIDs: Set<UUID>) -> PlayerCard {
        let allPlayers = game.players
        let trumpSuit = game.trumpSuit
        let aiService = self
        let probabilityThreshold = 0.3 // Risk threshold for breaking up melds/brisques
        
        print("🔍 AI DEBUG: chooseLeadCard - isEndgame: \(game.isEndgame), trumpSuit: \(trumpSuit?.rawValue ?? "nil")")
        print("🔍 AI DEBUG: Playable cards: \(playableCards.map { $0.displayName })")
        
        // Endgame: use void and trump inference
        if game.isEndgame {
            print("🔍 AI DEBUG: In endgame phase")
            
            // If any opponent is void in a suit, lead that suit to force trump or win
            for suit in Suit.allCases {
                let voidOpponents = allPlayers.filter { $0.id != player.id && opponentVoidSuits[$0.id]?.contains(suit) == true }
                if !voidOpponents.isEmpty {
                    print("🔍 AI DEBUG: Found void opponents for suit \(suit.rawValue): \(voidOpponents.map { $0.type.rawValue })")
                    let suitCards = playableCards.filter { $0.suit == suit }
                    if !suitCards.isEmpty {
                        let chosenCard = suitCards.sorted(by: { $0.rank > $1.rank }).first!
                        print("🔍 AI DEBUG: Leading with high \(suit.rawValue) to force trump: \(chosenCard.displayName)")
                        return chosenCard
                    }
                }
            }
            
            // Endgame: if opponents are out of trump, lead high non-trump
            print("🔍 AI DEBUG: Checking if opponents are out of trump...")
            if opponentsLikelyOutOfTrump(trumpSuit: trumpSuit, allPlayers: allPlayers, selfPlayer: player) {
                print("🔍 AI DEBUG: Opponents are out of trump! Looking for high non-trump cards...")
                let nonTrump = playableCards.filter { $0.suit != trumpSuit }
                print("🔍 AI DEBUG: Non-trump cards: \(nonTrump.map { $0.displayName })")
                if let best = nonTrump.sorted(by: { $0.rank > $1.rank }).first {
                    print("🔍 AI DEBUG: Leading with high non-trump: \(best.displayName)")
                    return best
                }
            } else {
                print("🔍 AI DEBUG: Opponents still have trump")
            }
        } else {
            print("🔍 AI DEBUG: In draw phase")
            // Draw phase: use probability to decide if it's safe to play meld/brisque
            let safeNonTrump = playableCards.filter { $0.suit != trumpSuit && !meldCardIDs.contains($0.id) && !$0.isBrisque }
            if !safeNonTrump.isEmpty {
                let chosenCard = safeNonTrump.sorted(by: { $0.rank < $1.rank }).first!
                print("🔍 AI DEBUG: Leading with safe non-trump: \(chosenCard.displayName)")
                return chosenCard
            }
            // If only meld/brisque cards are left, check probability of drawing a replacement
            let riskyCards = playableCards.filter { meldCardIDs.contains($0.id) || $0.isBrisque }
            for card in riskyCards {
                let prob = aiService.probabilityAIDrawsAnyCardOfType(suit: card.suit ?? .hearts, value: card.value ?? .ace, game: game, allPlayers: allPlayers, aiPlayer: player)
                if prob > probabilityThreshold {
                    print("🔍 AI DEBUG: Leading with risky card (prob \(prob) > \(probabilityThreshold)): \(card.displayName)")
                    return card
                }
            }
            // Otherwise, play the lowest card
            let chosenCard = playableCards.sorted(by: { $0.rank < $1.rank }).first!
            print("🔍 AI DEBUG: Leading with lowest card: \(chosenCard.displayName)")
            return chosenCard
        }
        // Fallback: lead lowest card
        let chosenCard = playableCards.sorted(by: { $0.rank < $1.rank }).first!
        print("🔍 AI DEBUG: Fallback - leading with lowest card: \(chosenCard.displayName)")
        return chosenCard
    }
    /// Enhanced follow card selection
    private func chooseFollowCard(player: Player, game: Game, playableCards: [PlayerCard], leadSuit: Suit?, trumpSuit: Suit?, meldCardIDs: Set<UUID>) -> PlayerCard {
        let allPlayers = game.players
        let aiService = self
        let probabilityThreshold = 0.3
        guard let leadSuit = leadSuit else { return playableCards.first! }
        let currentWinningCard = findCurrentWinningCard(game: game, leadSuit: leadSuit, trumpSuit: trumpSuit)
        // If can win and (in endgame) opponents are out of trump, win with lowest winning card
        if let winningCard = findWinningCard(playableCards: playableCards, currentWinner: currentWinningCard, leadSuit: leadSuit, trumpSuit: trumpSuit) {
            if game.isEndgame && opponentsLikelyOutOfTrump(trumpSuit: trumpSuit, allPlayers: allPlayers, selfPlayer: player) {
                // Only play brisque or meld card if it will win
                if winningCard.isBrisque || meldCardIDs.contains(winningCard.id) {
                    return winningCard
                }
            }
        }
        // If can't win or risk being trumped, play lowest card (prefer non-meld, non-brisque)
        let safe = playableCards.filter { !meldCardIDs.contains($0.id) && !$0.isBrisque }
        if !safe.isEmpty {
            return safe.sorted(by: { $0.rank < $1.rank }).first!
        }
        // Next, prefer non-meld cards
        let notMeld = playableCards.filter { !meldCardIDs.contains($0.id) }
        if !notMeld.isEmpty {
            return notMeld.sorted(by: { $0.rank < $1.rank }).first!
        }
        // Next, prefer non-brisque cards
        let notBrisque = playableCards.filter { !$0.isBrisque }
        if !notBrisque.isEmpty {
            return notBrisque.sorted(by: { $0.rank < $1.rank }).first!
        }
        // If only meld/brisque cards are left, check probability of drawing a replacement
        let riskyCards = playableCards.filter { meldCardIDs.contains($0.id) || $0.isBrisque }
        for card in riskyCards {
            let prob = aiService.probabilityAIDrawsAnyCardOfType(suit: card.suit ?? .hearts, value: card.value ?? .ace, game: game, allPlayers: allPlayers, aiPlayer: player)
            if prob > probabilityThreshold {
                return card
            }
        }
        // Otherwise, play the lowest card
        return playableCards.sorted(by: { $0.rank < $1.rank }).first!
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
    
    /// Determine which melds to declare
    func decideMeldsToDeclare(for player: Player, in game: Game) -> [Meld] {
        // No melds allowed in endgame
        if game.isEndgame {
            return []
        }
        let possibleMelds = game.getPossibleMelds(for: player)
        var meldsToDeclare: [Meld] = []
        let allPlayers = game.players
        let aiService = self
        let probabilityThreshold = 0.25 // Threshold for waiting for higher-value melds
        // --- OPTIMAL TRUMP SUIT SELECTION ---
        if game.trumpSuit == nil {
            let marriages = possibleMelds.filter { $0.type == .commonMarriage }
            if !marriages.isEmpty {
                // Score each suit by meld and trick potential
                var bestMarriage: Meld?
                var bestScore = -1
                for marriage in marriages {
                    guard let suit = marriage.cardIDs.compactMap({ player.cardByID($0)?.suit }).first else { continue }
                    // Meld potential: count possible future melds in this suit
                    let suitCards = player.cardsOfSuit(suit)
                    let meldPotential = suitCards.count * 2
                    // Trick potential: sum rank values
                    let trickPotential = suitCards.reduce(0) { $0 + $1.rank }
                    let score = meldPotential + trickPotential
                    if score > bestScore {
                        bestScore = score
                        bestMarriage = marriage
                    }
                }
                if let marriageToDeclare = bestMarriage {
                    return [marriageToDeclare]
                }
            }
        }
        // --- OPTIMAL MELD TIMING ---
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
            // --- Probability-based meld management ---
            // If only low-value melds are available, check if waiting for a higher meld is worthwhile
            let meldTypes = possibleMelds.map { $0.type }
            if !meldTypes.contains(.besigue) && !meldTypes.contains(.royalMarriage) {
                // Example: If missing a card for Bésigue, estimate probability of drawing it
                // Find what is missing for Bésigue
                let hasQueenSpades = player.hand.contains { $0.value == .queen && $0.suit == .spades }
                let hasJackDiamonds = player.hand.contains { $0.value == .jack && $0.suit == .diamonds }
                if hasQueenSpades != hasJackDiamonds { // Only missing one
                    let missingSuit: Suit = hasQueenSpades ? .diamonds : .spades
                    let missingValue: CardValue = hasQueenSpades ? .jack : .queen
                    let prob = aiService.probabilityAIDrawsAnyCardOfType(suit: missingSuit, value: missingValue, game: game, allPlayers: allPlayers, aiPlayer: player)
                    if prob > probabilityThreshold {
                        // Wait for higher-value meld
                        return []
                    }
                }
                // (Extend for other melds as needed)
            }
        }
        return meldsToDeclare
    }
    
    /// Probability that a specific unaccounted-for card is in the draw pile
    func probabilityCardInDrawPile(cardID: UUID, game: Game, allPlayers: [Player]) -> Double {
        // Find all unaccounted-for cards (not in any hand, played, or melded)
        var accountedFor = Set<UUID>()
        for player in allPlayers {
            for card in player.hand {
                accountedFor.insert(card.id)
            }
        }
        accountedFor.formUnion(cardMemory.playedCards.map { $0.id })
        accountedFor.formUnion(cardMemory.meldedCards.map { $0.id })
        let unaccounted = game.deck.cards.filter { !accountedFor.contains($0.id) }
        let D = game.deck.cards.count
        let O = allPlayers.filter { $0.type != .ai }.reduce(0) { $0 + $1.hand.count }
        let totalUnknown = D + O
        guard totalUnknown > 0 else { return 0.0 }
        // If the card is not unaccounted for, probability is 0
        guard unaccounted.contains(where: { $0.id == cardID }) else { return 0.0 }
        // Probability the card is in the draw pile
        return Double(D) / Double(totalUnknown)
    }
    
    /// Probability that at least one unaccounted-for card of a given suit/value is in the draw pile
    func probabilityAnyCardOfTypeInDrawPile(suit: Suit, value: CardValue, game: Game, allPlayers: [Player]) -> Double {
        // Find all unaccounted-for cards (not in any hand, played, or melded)
        var accountedFor = Set<UUID>()
        for player in allPlayers {
            for card in player.hand {
                accountedFor.insert(card.id)
            }
        }
        accountedFor.formUnion(cardMemory.playedCards.map { $0.id })
        accountedFor.formUnion(cardMemory.meldedCards.map { $0.id })
        let unaccounted = game.deck.cards.filter { !accountedFor.contains($0.id) }
        let matchingUnaccounted = unaccounted.filter { $0.suit == suit && $0.value == value }
        let D = game.deck.cards.count
        let O = allPlayers.filter { $0.type != .ai }.reduce(0) { $0 + $1.hand.count }
        let totalUnknown = D + O
        guard totalUnknown > 0 else { return 0.0 }
        // Expected number of matching cards in draw pile
        let expected = Double(matchingUnaccounted.count) * Double(D) / Double(totalUnknown)
        // Probability at least one is in draw pile (using complement rule)
        let pNone = pow(1.0 - Double(D) / Double(totalUnknown), Double(matchingUnaccounted.count))
        return 1.0 - pNone
    }

    /// Probability that the AI will draw a specific unaccounted-for card from the draw pile (in the next draw round)
    /// - Parameters:
    ///   - cardID: The UUID of the card in question
    ///   - game: The current game state
    ///   - allPlayers: All players in the game
    ///   - aiPlayer: The AI player (for hand exclusion)
    /// - Returns: Probability (0.0 to 1.0)
    func probabilityAIDrawsSpecificCard(cardID: UUID, game: Game, allPlayers: [Player], aiPlayer: Player) -> Double {
        // Find all unaccounted-for cards (not in any hand, played, or melded)
        var accountedFor = Set<UUID>()
        for player in allPlayers {
            for card in player.hand {
                accountedFor.insert(card.id)
            }
        }
        accountedFor.formUnion(cardMemory.playedCards.map { $0.id })
        accountedFor.formUnion(cardMemory.meldedCards.map { $0.id })
        let unaccounted = game.deck.cards.filter { !accountedFor.contains($0.id) }
        let D = game.deck.cards.count
        // If the card is not unaccounted for, probability is 0
        guard unaccounted.contains(where: { $0.id == cardID }) else { return 0.0 }
        // Probability the AI draws the card in the next draw round
        // Each player draws one card; if there are N players, each has 1/D chance
        // (Assuming fair shuffle, draw order does not matter)
        let N = allPlayers.count
        guard D > 0 else { return 0.0 }
        return 1.0 / Double(D)
    }

    /// Probability that the AI will draw any card of a given suit/value from the draw pile (in the next draw round)
    /// - Parameters:
    ///   - suit: The suit of the card
    ///   - value: The value of the card
    ///   - game: The current game state
    ///   - allPlayers: All players in the game
    ///   - aiPlayer: The AI player (for hand exclusion)
    /// - Returns: Probability (0.0 to 1.0)
    func probabilityAIDrawsAnyCardOfType(suit: Suit, value: CardValue, game: Game, allPlayers: [Player], aiPlayer: Player) -> Double {
        // Find all unaccounted-for cards (not in any hand, played, or melded)
        var accountedFor = Set<UUID>()
        for player in allPlayers {
            for card in player.hand {
                accountedFor.insert(card.id)
            }
        }
        accountedFor.formUnion(cardMemory.playedCards.map { $0.id })
        accountedFor.formUnion(cardMemory.meldedCards.map { $0.id })
        let unaccounted = game.deck.cards.filter { !accountedFor.contains($0.id) }
        let matchingUnaccounted = unaccounted.filter { $0.suit == suit && $0.value == value }
        let D = game.deck.cards.count
        guard D > 0 else { return 0.0 }
        // Probability the AI draws any one of the matching cards in the next draw round
        // For k matching cards, probability = k / D
        return Double(matchingUnaccounted.count) / Double(D)
    }
}

// --- ENDGAME HELPERS ---
private func shouldLeadWithJokerInEndgame(player: Player, game: Game, playableCards: [PlayerCard]) -> Bool {
    // In endgame, leading with a Joker is strategic - to force opponents to waste trumps
    // The Joker will likely lose, but it's a sacrificial play for strategic advantage
    
    let jokers = playableCards.filter { $0.isJoker }
    guard !jokers.isEmpty else { return false }
    
    // Strategic reasons to lead with a Joker:
    // 1. If AI has high brisques to protect later
    // 2. If AI wants to probe what trumps opponents have
    // 3. If AI has multiple Jokers (can afford to sacrifice one)
    // 4. If AI has strong follow-up cards after forcing trumps
    
    let brisques = player.held.filter { $0.isBrisque }
    let hasHighBrisques = brisques.contains { $0.value == .ace || $0.value == .ten }
    let hasMultipleJokers = jokers.count > 1
    
    // Lead with Joker if AI has high brisques to protect or multiple Jokers
    return hasHighBrisques || hasMultipleJokers
}

private func handleJokerFollowInEndgame(player: Player, game: Game, playableCards: [PlayerCard], trumpSuit: Suit?) -> PlayerCard {
    // If AI has a trump, play the lowest trump. Otherwise, discard lowest card.
    let trumps = playableCards.filter { $0.suit == trumpSuit }
    if let lowestTrump = trumps.min(by: { $0.rank < $1.rank }) {
        return lowestTrump
    }
    // If AI has a Joker, play it (to avoid revealing trump strength)
    if let joker = playableCards.first(where: { $0.isJoker }) {
        return joker
    }
    // Otherwise, discard lowest value card
    return playableCards.min(by: { $0.rank < $1.rank }) ?? playableCards.first!
}

private func chooseLeadCardEndgame(player: Player, game: Game, playableCards: [PlayerCard]) -> PlayerCard {
    // Prioritize brisques if AI needs more to reach 5
    let brisques = playableCards.filter { $0.isBrisque }
    let brisquesNeeded = max(0, 5 - game.brisques[player.id, default: 0])
    if brisquesNeeded > 0, let brisque = brisques.max(by: { $0.rank < $1.rank }) {
        return brisque
    }
    // Otherwise, lead lowest non-trump, non-brisque card
    let nonTrumps = playableCards.filter { !$0.isJoker && $0.suit != game.trumpSuit }
    if let lowest = nonTrumps.min(by: { $0.rank < $1.rank }) {
        return lowest
    }
    // Otherwise, lead lowest card
    return playableCards.min(by: { $0.rank < $1.rank }) ?? playableCards.first!
}

private func chooseFollowCardEndgame(player: Player, game: Game, playableCards: [PlayerCard], leadSuit: Suit?, trumpSuit: Suit?) -> PlayerCard {
    // Must follow suit if possible
    if let suit = leadSuit {
        let matching = playableCards.filter { $0.suit == suit }
        if !matching.isEmpty {
            // If can win, play lowest card that wins
            if let highestOnTable = game.currentTrick.filter({ $0.suit == suit }).max(by: { $0.rank < $1.rank }) {
                let winning = matching.filter { $0.rank > highestOnTable.rank }
                if let lowestWinning = winning.min(by: { $0.rank < $1.rank }) {
                    return lowestWinning
                }
            }
            // Otherwise, play lowest in suit
            return matching.min(by: { $0.rank < $1.rank })!
        }
    }
    // If can't follow suit, must play trump if possible
    let trumps = playableCards.filter { $0.suit == trumpSuit }
    if !trumps.isEmpty {
        // Play lowest trump that can win, else lowest trump
        if let highestTrumpOnTable = game.currentTrick.filter({ $0.suit == trumpSuit }).max(by: { $0.rank < $1.rank }) {
            let winning = trumps.filter { $0.rank > highestTrumpOnTable.rank }
            if let lowestWinning = winning.min(by: { $0.rank < $1.rank }) {
                return lowestWinning
            }
        }
        return trumps.min(by: { $0.rank < $1.rank })!
    }
    // Otherwise, discard lowest value card
    return playableCards.min(by: { $0.rank < $1.rank }) ?? playableCards.first!
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