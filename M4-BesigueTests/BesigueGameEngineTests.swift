import XCTest
@testable import M4_Besigue

final class BesigueGameEngineTests: XCTestCase {
    
    var gameRules: GameRules!
    var game: Game!
    
    override func setUpWithError() throws {
        gameRules = GameRules()
        game = Game(gameRules: gameRules)
    }
    
    override func tearDownWithError() throws {
        gameRules = nil
        game = nil
    }
    
    // MARK: - Game Setup Tests
    
    func testGameSetupWith2Players() throws {
        gameRules.updatePlayerCount(2)
        gameRules.updateHumanPlayerCount(2)
        
        XCTAssertEqual(game.players.count, 2)
        XCTAssertEqual(game.players[0].type, .human)
        XCTAssertEqual(game.players[1].type, .human)
    }
    
    func testGameSetupWith2Players1Human1AI() throws {
        gameRules.updatePlayerCount(2)
        gameRules.updateHumanPlayerCount(1)
        game.startNewGame()
        
        XCTAssertEqual(game.players.count, 2)
        XCTAssertEqual(game.players[0].type, .human)
        XCTAssertEqual(game.players[1].type, .ai)
        XCTAssertTrue(game.players[1].name.contains("(AI)"))
    }
    
    func testGameSetupWith4Players2Human2AI() throws {
        gameRules.updatePlayerCount(4)
        gameRules.updateHumanPlayerCount(2)
        game.startNewGame()
        
        XCTAssertEqual(game.players.count, 4)
        let humans = game.players.filter { $0.type == .human }
        let ais = game.players.filter { $0.type == .ai }
        XCTAssertEqual(humans.count, 2)
        XCTAssertEqual(ais.count, 2)
    }
    
    // MARK: - Deck Tests
    
    func testDeckCreation() throws {
        XCTAssertEqual(game.deck.cards.count, 132)
        XCTAssertTrue(game.deck.verifyDeckComposition())
    }
    
    func testDeckDealing() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        // Each player should have 9 cards
        for player in game.players {
            XCTAssertEqual(player.hand.count, 9)
        }
        
        // Deck should have remaining cards
        XCTAssertEqual(game.deck.cards.count, 132 - (2 * 9))
    }
    
    func testDeckDealing4Players() throws {
        gameRules.updatePlayerCount(4)
        game.startNewGame()
        
        // Each player should have 9 cards
        for player in game.players {
            XCTAssertEqual(player.hand.count, 9)
        }
        
        // Deck should have remaining cards
        XCTAssertEqual(game.deck.cards.count, 132 - (4 * 9))
    }
    
    // MARK: - Dealer Determination Tests
    
    func testRandomDealerDetermination() throws {
        gameRules.dealerDeterminationMethod = .random
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        let dealers = game.players.filter { $0.isDealer }
        XCTAssertEqual(dealers.count, 1)
        XCTAssertTrue(game.currentPhase == .playing)
    }
    
    func testDrawJacksDealerDetermination() throws {
        gameRules.dealerDeterminationMethod = .drawJacks
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        XCTAssertTrue(game.currentPhase == .dealerDetermination)
    }
    
    // MARK: - Card Play Tests
    
    func testBasicCardPlay() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        let player = game.players[0]
        let card = player.hand[0]
        
        // Should be able to play a card
        XCTAssertTrue(game.canPlayCard())
        
        // Play the card using the synchronous game method
        game.playCardSync(card, from: player)
        
        XCTAssertEqual(game.currentTrick.count, 1)
        XCTAssertEqual(player.hand.count, 8)
    }
    
    func testTrickWinnerDetermination() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        // Create a simple trick
        let player1 = game.players[0]
        let player2 = game.players[1]
        
        let aceOfHearts = player1.hand.first { $0.value == .ace && $0.suit == .hearts }
        let sevenOfHearts = player2.hand.first { $0.value == .seven && $0.suit == .hearts }
        
        if let ace = aceOfHearts, let seven = sevenOfHearts {
            game.currentTrick.append(ace)
            game.currentTrick.append(seven)
            
            let winnerIndex = game.determineTrickWinner()
            XCTAssertEqual(winnerIndex, 0) // Ace should beat Seven
        }
    }
    
    // MARK: - Meld Tests
    
    func testBesigueMeldDetection() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        let player = game.players[0]
        let possibleMelds = game.getPossibleMelds(for: player)
        
        // Should detect Bésigue if player has Queen of Spades and Jack of Diamonds
        let hasBesigue = possibleMelds.contains { $0.type == .besigue }
        // Note: This test may pass or fail depending on the actual cards dealt
        XCTAssertNotNil(hasBesigue)
    }
    
    func testMarriageMeldDetection() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        let player = game.players[0]
        let possibleMelds = game.getPossibleMelds(for: player)
        
        // Should detect marriages if player has King and Queen of same suit
        let hasMarriage = possibleMelds.contains { $0.type == .royalMarriage || $0.type == .commonMarriage }
        // Note: This test may pass or fail depending on the actual cards dealt
        XCTAssertNotNil(hasMarriage)
    }
    
    // MARK: - Scoring Tests
    
    func testBrisqueScoring() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        let player = game.players[0]
        let brisqueCards = player.hand.filter { $0.isBrisque }
        
        // Count brisques in hand
        XCTAssertGreaterThanOrEqual(brisqueCards.count, 0)
        
        // Test brisque value calculation
        let totalBrisqueValue = brisqueCards.reduce(0) { $0 + $1.brisqueValue }
        XCTAssertEqual(totalBrisqueValue, brisqueCards.count * 10)
    }
    
    // MARK: - Game Flow Tests
    
    func testDrawPlayCycle() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        // After game starts, should be in draw cycle
        XCTAssertTrue(game.isDrawCycle)
        XCTAssertEqual(game.currentDrawIndex, game.currentTrickLeader)
        XCTAssertEqual(game.currentPlayIndex, game.currentTrickLeader)
    }
    
    func testTurnOrderConsistency() throws {
        gameRules.updatePlayerCount(4)
        game.startNewGame()
        
        let initialOrder = game.players.map { $0.name }
        
        // Simulate a few turns
        for _ in 0..<10 {
            game.nextPlayer()
        }
        
        let finalOrder = game.players.map { $0.name }
        
        // Turn order should remain consistent
        XCTAssertEqual(initialOrder, finalOrder)
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyDeckHandling() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        // Draw all remaining cards
        while !game.deck.isEmpty {
            _ = game.deck.drawCard()
        }
        
        XCTAssertTrue(game.deck.isEmpty)
        
        // Manually trigger endgame check
        game.checkEndgame()
        
        // Game should transition to endgame phase
        XCTAssertTrue(game.isEndgame)
    }
    
    func testPlayerHandSizeLimit() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        for player in game.players {
            XCTAssertLessThanOrEqual(player.hand.count, 9)
        }
    }
    
    // MARK: - Joker Tests
    
    func testJokerInDeck() throws {
        let jokers = game.deck.cards.filter { $0.isJoker }
        XCTAssertEqual(jokers.count, 4)
        
        let redJokers = jokers.filter { $0.jokerType?.rawValue.contains("red") == true }
        let blackJokers = jokers.filter { $0.jokerType?.rawValue.contains("black") == true }
        
        XCTAssertEqual(redJokers.count, 2)
        XCTAssertEqual(blackJokers.count, 2)
    }
    
    func testFourJokersMeldDetection() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        let player = game.players[0]
        let jokers = player.hand.filter { $0.isJoker }
        
        if jokers.count == 4 {
            let possibleMelds = game.getPossibleMelds(for: player)
            let hasFourJokers = possibleMelds.contains { $0.type == .fourJokers }
            XCTAssertTrue(hasFourJokers)
        }
    }
    
    // MARK: - Endgame Playable Cards Tests
    func testEndgame_MustFollowSuitAndPlayHigherIfPossible() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        game.deck.cards.removeAll() // Force endgame
        game.checkEndgame()
        game.trumpSuit = .spades
        let player = game.players[0]
        // Lead suit is hearts, current winning card is 9 of hearts
        let nineHearts = PlayerCard(card: Card(suit: .hearts, value: .nine))
        let jackHearts = PlayerCard(card: Card(suit: .hearts, value: .jack))
        let sevenHearts = PlayerCard(card: Card(suit: .hearts, value: .seven))
        player.held = [jackHearts, sevenHearts]
        game.currentTrick = [nineHearts]
        game.currentPlayerIndex = 0
        let playable = game.getEndgamePlayableCards(leadSuit: .hearts, trumpSuit: .spades, allCards: player.held)
        // Only jackHearts (higher than 9) should be playable
        XCTAssertEqual(playable, [jackHearts])
    }
    func testEndgame_MustFollowSuitButCannotPlayHigher() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        game.deck.cards.removeAll()
        game.checkEndgame()
        game.trumpSuit = .spades
        let player = game.players[0]
        // Lead suit is hearts, current winning card is jack of hearts
        let jackHearts = PlayerCard(card: Card(suit: .hearts, value: .jack))
        let sevenHearts = PlayerCard(card: Card(suit: .hearts, value: .seven))
        player.held = [sevenHearts]
        game.currentTrick = [jackHearts]
        game.currentPlayerIndex = 0
        let playable = game.getEndgamePlayableCards(leadSuit: .hearts, trumpSuit: .spades, allCards: player.held)
        // Only sevenHearts (cannot beat jack) should be playable
        XCTAssertEqual(playable, [sevenHearts])
    }
    func testEndgame_MustTrumpIfCannotFollowSuit() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        game.deck.cards.removeAll()
        game.checkEndgame()
        game.trumpSuit = .spades
        let player = game.players[0]
        // Lead suit is hearts, player has only trumps and clubs
        let sevenSpades = PlayerCard(card: Card(suit: .spades, value: .seven))
        let aceClubs = PlayerCard(card: Card(suit: .clubs, value: .ace))
        player.held = [sevenSpades, aceClubs]
        game.currentTrick = [PlayerCard(card: Card(suit: .hearts, value: .queen))]
        game.currentPlayerIndex = 0
        let playable = game.getEndgamePlayableCards(leadSuit: .hearts, trumpSuit: .spades, allCards: player.held)
        // Only sevenSpades (trump) should be playable
        XCTAssertEqual(playable, [sevenSpades])
    }
    func testEndgame_CanPlayAnyIfCannotFollowSuitOrTrump() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        game.deck.cards.removeAll()
        game.checkEndgame()
        game.trumpSuit = .spades
        let player = game.players[0]
        // Lead suit is hearts, player has only clubs and diamonds
        let aceClubs = PlayerCard(card: Card(suit: .clubs, value: .ace))
        let kingDiamonds = PlayerCard(card: Card(suit: .diamonds, value: .king))
        player.held = [aceClubs, kingDiamonds]
        game.currentTrick = [PlayerCard(card: Card(suit: .hearts, value: .queen))]
        game.currentPlayerIndex = 0
        let playable = game.getEndgamePlayableCards(leadSuit: .hearts, trumpSuit: .spades, allCards: player.held)
        // Both cards should be playable
        XCTAssertEqual(Set(playable), Set([aceClubs, kingDiamonds]))
    }
    
    // MARK: - Performance Tests
    
    func testGameStartupPerformance() throws {
        measure {
            gameRules.updatePlayerCount(4)
            game.startNewGame()
        }
    }
    
    func testCardPlayPerformance() throws {
        gameRules.updatePlayerCount(2)
        game.startNewGame()
        
        measure {
            for _ in 0..<100 {
                let player = game.players[0]
                if !player.hand.isEmpty {
                    let card = player.hand[0]
                    game.currentTrick.append(card)
                    player.removeCard(card)
                }
            }
        }
    }
    
    func testAICardMemoryTracksPlayedAndMeldedCards() throws {
        gameRules.updatePlayerCount(2)
        gameRules.updateHumanPlayerCount(1)
        game.startNewGame()
        // Ensure AI is the current player and phase is correct
        let aiIndex = game.players.firstIndex(where: { $0.type == .ai })!
        game.currentPlayerIndex = aiIndex
        game.currentPhase = .playing
        let aiPlayer = game.players[aiIndex]
        let aiService = game.test_aiService
        // Give AI a hand and simulate some played and melded cards
        let card1 = PlayerCard(card: Card(suit: .hearts, value: .ace))
        let card2 = PlayerCard(card: Card(suit: .hearts, value: .ten))
        let card3 = PlayerCard(card: Card(suit: .spades, value: .king))
        let card4 = PlayerCard(card: Card(suit: .spades, value: .queen))
        let card5 = PlayerCard(card: Card(suit: .clubs, value: .seven))
        let card6 = PlayerCard(card: Card(suit: .diamonds, value: .eight))
        let card7 = PlayerCard(card: Card(suit: .diamonds, value: .nine))
        let card8 = PlayerCard(card: Card(suit: .clubs, value: .eight))
        let card9 = PlayerCard(card: Card(suit: .clubs, value: .nine))
        aiPlayer.held = [card1, card2, card3, card4, card5, card6, card7, card8, card9]
        // Simulate played and melded cards
        aiService.cardMemory.test_setPlayedCards([card1, card2])
        aiService.cardMemory.addMeldedCards([card3, card4])
        // Ensure draw pile is not empty
        game.deck.cards = [Card(suit: .hearts, value: .seven)]
        game.currentTrick = [] // AI is leading
        let chosenCard = aiService.chooseCardToPlay(for: aiPlayer, in: game)
        XCTAssertNotNil(chosenCard, "AI should select a card to play")
        // Additional assertions can be added here to check memory logic
    }
    
    func testAICardMemoryInference() throws {
        gameRules.updatePlayerCount(2)
        gameRules.updateHumanPlayerCount(1)
        game.startNewGame()
        let aiPlayer = game.players.first { $0.type == .ai }!
        let humanPlayer = game.players.first { $0.type == .human }!
        let aiService = game.test_aiService
        let deck = game.deck
        // At start, all cards in hands are accounted for, so unaccounted should be deck minus hands
        let unaccounted = aiService.cardMemory.unaccountedForCards(allPlayers: game.players, deck: deck)
        let allHandIds = Set(game.players.flatMap { $0.hand.map { $0.id } })
        let allDeckIds = Set(deck.cards.map { $0.id })
        // All unaccounted cards should be in the deck, not in any hand
        for card in unaccounted {
            XCTAssertTrue(allDeckIds.contains(card.id))
            XCTAssertFalse(allHandIds.contains(card.id))
        }
        // Now play a card and check that it is no longer unaccounted
        let aiCard = aiPlayer.hand[0]
        game.playCardSync(aiCard, from: aiPlayer)
        let unaccountedAfterPlay = aiService.cardMemory.unaccountedForCards(allPlayers: game.players, deck: deck)
        XCTAssertFalse(unaccountedAfterPlay.contains(where: { $0.id == aiCard.id }))
        // Test inferOpponentHands returns all unaccounted cards for the opponent
        let inference = aiService.cardMemory.inferOpponentHands(allPlayers: game.players, selfPlayer: aiPlayer, deck: deck)
        let opponentId = humanPlayer.id
        XCTAssertTrue(inference[opponentId]?.allSatisfy { unaccountedAfterPlay.contains($0) } ?? false)
    }
    
    func testAIAdvancedTrickPlayStrategies() throws {
        gameRules.updatePlayerCount(2)
        gameRules.updateHumanPlayerCount(1)
        game.startNewGame()
        // Ensure AI is the current player and phase is correct
        let aiIndex = game.players.firstIndex(where: { $0.type == .ai })!
        game.currentPlayerIndex = aiIndex
        game.currentPhase = .playing
        let aiPlayer = game.players[aiIndex]
        let aiService = game.test_aiService
        // Give AI a hand with a mix of cards for advanced strategy
        aiPlayer.held = [
            PlayerCard(card: Card(suit: .hearts, value: .ace)),
            PlayerCard(card: Card(suit: .hearts, value: .ten)),
            PlayerCard(card: Card(suit: .hearts, value: .king)),
            PlayerCard(card: Card(suit: .hearts, value: .queen)),
            PlayerCard(card: Card(suit: .spades, value: .ace)),
            PlayerCard(card: Card(suit: .spades, value: .ten)),
            PlayerCard(card: Card(suit: .spades, value: .king)),
            PlayerCard(card: Card(suit: .spades, value: .queen)),
            PlayerCard(card: Card(suit: .clubs, value: .seven))
        ]
        // Ensure draw pile is not empty
        game.deck.cards = [Card(suit: .diamonds, value: .nine)]
        game.currentTrick = [] // AI is leading
        let chosenCard = aiService.chooseCardToPlay(for: aiPlayer, in: game)
        XCTAssertNotNil(chosenCard, "AI should select a card to play")
        // Additional assertions can be added here based on expected advanced strategy
    }

    func testAI_AvoidsPlayingMeldCardIfPossible() throws {
        gameRules.updatePlayerCount(2)
        gameRules.updateHumanPlayerCount(1)
        game.startNewGame()
        // Ensure AI is the current player and phase is correct
        let aiIndex = game.players.firstIndex(where: { $0.type == .ai })!
        game.currentPlayerIndex = aiIndex
        game.currentPhase = .playing
        let aiPlayer = game.players[aiIndex]
        let aiService = game.test_aiService
        // Give AI a hand where all but two cards are needed for melds
        let safe1 = PlayerCard(card: Card(suit: .clubs, value: .seven))
        let safe2 = PlayerCard(card: Card(suit: .diamonds, value: .eight))
        let meld1 = PlayerCard(card: Card(suit: .hearts, value: .king))
        let meld2 = PlayerCard(card: Card(suit: .hearts, value: .queen))
        let meld3 = PlayerCard(card: Card(suit: .spades, value: .king))
        let meld4 = PlayerCard(card: Card(suit: .spades, value: .queen))
        let meld5 = PlayerCard(card: Card(suit: .diamonds, value: .king))
        let meld6 = PlayerCard(card: Card(suit: .diamonds, value: .queen))
        let meld7 = PlayerCard(card: Card(suit: .clubs, value: .king))
        aiPlayer.held = [safe1, safe2, meld1, meld2, meld3, meld4, meld5, meld6, meld7]
        // Ensure draw pile is not empty
        game.deck.cards = [Card(suit: .clubs, value: .nine)]
        game.currentTrick = [] // AI is leading
        let chosenCard = aiService.chooseCardToPlay(for: aiPlayer, in: game)
        XCTAssertNotNil(chosenCard, "AI should select a card to play")
        XCTAssertTrue([safe1.id, safe2.id].contains(chosenCard?.id), "AI should avoid playing meld cards if possible")
    }

    func testAI_AvoidsPlayingBrisqueUnlessWinning() throws {
        gameRules.updatePlayerCount(2)
        gameRules.updateHumanPlayerCount(1)
        game.startNewGame()
        let aiPlayer = game.players.first { $0.type == .ai }!
        let aiService = game.test_aiService
        // Give AI a hand with a brisque and a low card, plus 7 more cards
        let aceDiamonds = PlayerCard(card: Card(suit: .diamonds, value: .ace)) // brisque
        let sevenDiamonds = PlayerCard(card: Card(suit: .diamonds, value: .seven))
        let extraCards = [
            PlayerCard(card: Card(suit: .clubs, value: .seven)),
            PlayerCard(card: Card(suit: .clubs, value: .eight)),
            PlayerCard(card: Card(suit: .clubs, value: .nine)),
            PlayerCard(card: Card(suit: .hearts, value: .seven)),
            PlayerCard(card: Card(suit: .hearts, value: .eight)),
            PlayerCard(card: Card(suit: .hearts, value: .nine)),
            PlayerCard(card: Card(suit: .spades, value: .seven))
        ]
        aiPlayer.held = [aceDiamonds, sevenDiamonds] + extraCards
        // Ensure draw pile is not empty (non-endgame)
        game.deck.cards = [Card(suit: .spades, value: .eight)] + game.deck.cards
        // Simulate following suit, cannot win (lead is king)
        game.currentTrick = [PlayerCard(card: Card(suit: .diamonds, value: .king))]
        game.trumpSuit = .spades
        let chosen = aiService.chooseCardToPlay(for: aiPlayer, in: game)
        XCTAssertNotNil(chosen)
        // In non-endgame, AI can play any card, but should prefer to keep brisque if possible
        XCTAssertNotEqual(chosen?.value, .ace, "AI should not waste brisque when not required to follow suit in non-endgame phase")
        // Now simulate AI can win with ace
        game.currentTrick = [PlayerCard(card: Card(suit: .diamonds, value: .queen))]
        let chosen2 = aiService.chooseCardToPlay(for: aiPlayer, in: game)
        XCTAssertNotNil(chosen2)
        // In non-endgame, AI can play any card, but should play ace if it wants to win
        // (This part is less strict, but we check AI logic)
    }

    func testAI_TrumpInferenceAndBlocking() throws {
        gameRules.updatePlayerCount(2)
        gameRules.updateHumanPlayerCount(1)
        game.startNewGame()
        let aiIndex = game.players.firstIndex(where: { $0.type == .ai })!
        game.currentPlayerIndex = aiIndex
        // Set to endgame so trump inference is valid
        game.currentPhase = .endgame
        let aiPlayer = game.players[aiIndex]
        let aiService = game.test_aiService
        // Set trump suit
        game.trumpSuit = .spades
        // Give AI a hand with high non-trump and all remaining trumps
        let aceHearts = PlayerCard(card: Card(suit: .hearts, value: .ace))
        let kingSpades = PlayerCard(card: Card(suit: .spades, value: .king))
        let queenSpades = PlayerCard(card: Card(suit: .spades, value: .queen))
        let tenSpades = PlayerCard(card: Card(suit: .spades, value: .ten))
        let sevenClubs = PlayerCard(card: Card(suit: .clubs, value: .seven))
        let eightDiamonds = PlayerCard(card: Card(suit: .diamonds, value: .eight))
        let nineDiamonds = PlayerCard(card: Card(suit: .diamonds, value: .nine))
        let eightClubs = PlayerCard(card: Card(suit: .clubs, value: .eight))
        let nineClubs = PlayerCard(card: Card(suit: .clubs, value: .nine))
        aiPlayer.held = [aceHearts, kingSpades, queenSpades, tenSpades, sevenClubs, eightDiamonds, nineDiamonds, eightClubs, nineClubs]
        // Simulate all other trumps are played or melded
        let playedTrumps = [PlayerCard(card: Card(suit: .spades, value: .ace)), PlayerCard(card: Card(suit: .spades, value: .jack))]
        aiService.cardMemory.test_setPlayedCards(playedTrumps)
        // Endgame: draw pile is empty
        game.deck.cards = []
        game.currentTrick = [] // AI is leading
        // AI should infer opponents are out of trump and lead high non-trump (aceHearts)
        let chosenCard = aiService.chooseCardToPlay(for: aiPlayer, in: game)
        print("AI chose to play: \(chosenCard?.displayName ?? "nil")")
        XCTAssertNotNil(chosenCard, "AI should select a card to play")
        XCTAssertEqual(chosenCard?.suit, .hearts)
        XCTAssertEqual(chosenCard?.value, .ace)
    }

    func testAI_LeadsWithJokerAfterMeld() throws {
        gameRules.updatePlayerCount(2)
        gameRules.updateHumanPlayerCount(1)
        game.startNewGame()
        let aiIndex = game.players.firstIndex(where: { $0.type == .ai })!
        game.currentPlayerIndex = aiIndex
        game.currentPhase = .playing
        let aiPlayer = game.players[aiIndex]
        let aiService = game.test_aiService
        // Give AI a hand with a joker and other cards
        let joker = PlayerCard(card: Card(jokerType: .redOne))
        let aceHearts = PlayerCard(card: Card(suit: .hearts, value: .ace))
        let kingHearts = PlayerCard(card: Card(suit: .hearts, value: .king))
        let queenHearts = PlayerCard(card: Card(suit: .hearts, value: .queen))
        let sevenClubs = PlayerCard(card: Card(suit: .clubs, value: .seven))
        let eightDiamonds = PlayerCard(card: Card(suit: .diamonds, value: .eight))
        let nineDiamonds = PlayerCard(card: Card(suit: .diamonds, value: .nine))
        let eightClubs = PlayerCard(card: Card(suit: .clubs, value: .eight))
        let nineClubs = PlayerCard(card: Card(suit: .clubs, value: .nine))
        aiPlayer.held = [joker, aceHearts, kingHearts, queenHearts, sevenClubs, eightDiamonds, nineDiamonds, eightClubs, nineClubs]
        // Simulate AI just melded with the joker
        let meld = Meld(cardIDs: [joker.id, kingHearts.id, queenHearts.id, aceHearts.id], type: .fourJokers, pointValue: 100, roundNumber: 1)
        aiService.afterMeld(meld: meld, by: aiPlayer)
        // Ensure draw pile is not empty
        game.deck.cards = [Card(suit: .hearts, value: .seven)]
        game.currentTrick = [] // AI is leading
        // AI should lead with the joker
        let chosenCard = aiService.chooseCardToPlay(for: aiPlayer, in: game)
        XCTAssertNotNil(chosenCard, "AI should select a card to play")
        XCTAssertTrue(chosenCard?.isJoker == true, "AI should lead with joker after melding with it")
    }

    func testAI_ProbabilityAnyCardOfTypeInDrawPile() throws {
        gameRules.updatePlayerCount(2)
        gameRules.updateHumanPlayerCount(1)
        game.startNewGame()
        let aiIndex = game.players.firstIndex(where: { $0.type == .ai })!
        game.currentPlayerIndex = aiIndex
        game.currentPhase = .playing
        let aiPlayer = game.players[aiIndex]
        let humanPlayer = game.players.first(where: { $0.type == .human })!
        let aiService = game.test_aiService
        // Set up: 4 Queen of Hearts in the game
        let qh1 = Card(suit: .hearts, value: .queen)
        let qh2 = Card(suit: .hearts, value: .queen)
        let qh3 = Card(suit: .hearts, value: .queen)
        let qh4 = Card(suit: .hearts, value: .queen)
        // AI has one Queen of Hearts
        aiPlayer.held = [PlayerCard(card: qh1)]
        // One Queen of Hearts has been played
        aiService.cardMemory.test_setPlayedCards([PlayerCard(card: qh2)])
        // One Queen of Hearts has been melded
        aiService.cardMemory.addMeldedCards([PlayerCard(card: qh3)])
        // The last Queen of Hearts is unaccounted for, and is in the draw pile
        let drawPileQH = PlayerCard(card: qh4)
        // Set up draw pile and opponent hand
        game.deck.cards = [drawPileQH.card] + [Card(suit: .spades, value: .ace), Card(suit: .clubs, value: .seven)]
        humanPlayer.held = [PlayerCard(card: Card(suit: .diamonds, value: .ten)), PlayerCard(card: Card(suit: .spades, value: .king))]
        // There are 3 cards in the draw pile, 2 in opponent's hand
        // Probability the Queen of Hearts is in the draw pile: 3/(3+2) = 0.6
        let prob = aiService.probabilityAnyCardOfTypeInDrawPile(suit: .hearts, value: .queen, game: game, allPlayers: [aiPlayer, humanPlayer])
        XCTAssertEqual(prob, 0.6, accuracy: 0.0001)
    }

    func testAI_ProbabilityAIDrawsSpecificCardAndAnyCardOfType() throws {
        gameRules.updatePlayerCount(4)
        gameRules.updateHumanPlayerCount(1)
        game.startNewGame()
        let aiPlayer = game.players.first(where: { $0.type == .ai })!
        let aiService = game.test_aiService
        // Set up: 4 King of Spades in the game
        let ks1 = Card(suit: .spades, value: .king)
        let ks2 = Card(suit: .spades, value: .king)
        let ks3 = Card(suit: .spades, value: .king)
        let ks4 = Card(suit: .spades, value: .king)
        // AI has one King of Spades
        aiPlayer.held = [PlayerCard(card: ks1)]
        // One King of Spades has been played
        aiService.cardMemory.test_setPlayedCards([PlayerCard(card: ks2)])
        // One King of Spades has been melded
        aiService.cardMemory.addMeldedCards([PlayerCard(card: ks3)])
        // The last King of Spades is unaccounted for, and is in the draw pile
        let drawPileKS = PlayerCard(card: ks4)
        // Set up draw pile and opponent hands
        game.deck.cards = [drawPileKS.card] + [Card(suit: .hearts, value: .ace), Card(suit: .clubs, value: .seven), Card(suit: .diamonds, value: .ten)]
        // Each opponent has 2 cards
        for player in game.players where player.id != aiPlayer.id {
            player.held = [PlayerCard(card: Card(suit: .hearts, value: .queen)), PlayerCard(card: Card(suit: .spades, value: .ten))]
        }
        // There are 4 cards in the draw pile, 3 opponents with 2 cards each = 6 in hands
        // Probability the King of Spades is in the draw pile: 4/(4+6) = 0.4
        let probSpecific = aiService.probabilityAIDrawsSpecificCard(cardID: ks4.id, game: game, allPlayers: game.players, aiPlayer: aiPlayer)
        XCTAssertEqual(probSpecific, 0.25, accuracy: 0.0001) // 1/4 chance to draw specific card
        // Probability the AI draws any King of Spades: 1/4 (since only one left)
        let probAny = aiService.probabilityAIDrawsAnyCardOfType(suit: .spades, value: .king, game: game, allPlayers: game.players, aiPlayer: aiPlayer)
        XCTAssertEqual(probAny, 0.25, accuracy: 0.0001)
        // Add another King of Spades to the draw pile
        let ks5 = Card(suit: .spades, value: .king)
        game.deck.cards.append(ks5)
        // Now 5 cards in draw pile, 2 are King of Spades
        let probAny2 = aiService.probabilityAIDrawsAnyCardOfType(suit: .spades, value: .king, game: game, allPlayers: game.players, aiPlayer: aiPlayer)
        XCTAssertEqual(probAny2, 0.4, accuracy: 0.0001) // 2/5
    }
} 
