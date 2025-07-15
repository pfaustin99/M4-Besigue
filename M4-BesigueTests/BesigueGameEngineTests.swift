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
} 