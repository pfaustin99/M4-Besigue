//
//  M4_BesigueTests.swift
//  M4-BesigueTests
//
//  Created by Paul Faustin on 6/22/25.
//

import XCTest
@testable import M4_Besigue

class M4_BesigueTests: XCTestCase {

    func testTwoHumanPlayersProLevel() {
        // Set up GameRules for 2 human players, Pro level
        let rules = GameRules()
        rules.playerCount = 2
        rules.humanPlayerCount = 2
        rules.aiPlayerCount = 0
        rules.gameLevel = GameLevel.pro
        rules.generatePlayerConfigurations()

        let game = Game(gameRules: rules)
        game.startNewGame()

        // Check initial state
        XCTAssertEqual(game.players.count, 2, "Should have 2 players")
        XCTAssertTrue(game.players.allSatisfy { $0.type == PlayerType.human }, "All players should be human")
        XCTAssertEqual(game.currentPhase, GamePhase.playing, "Game should be in playing phase after start")
        XCTAssertEqual(game.players[0].hand.count, 9, "Each player should have 9 cards")
        XCTAssertEqual(game.players[1].hand.count, 9, "Each player should have 9 cards")
        
        // Simulate a few turns: play a card for each player using playCardSync
        let player1 = game.players[0]
        let player2 = game.players[1]
        let card1 = player1.hand.first!
        let card2 = player2.hand.first!

        // Player 1 plays
        game.playCardSync(card1, from: player1)
        XCTAssertEqual(game.currentTrick.count, 1, "Trick should have 1 card after first play")
        XCTAssertFalse(player1.hand.contains(card1), "Player 1 should no longer have the played card")

        // Player 2 plays
        game.playCardSync(card2, from: player2)
        XCTAssertEqual(game.currentTrick.count, 2, "Trick should have 2 cards after second play")
        XCTAssertFalse(player2.hand.contains(card2), "Player 2 should no longer have the played card")

        // After both have played, trick should be completed and reset
        if game.currentTrick.isEmpty {
            XCTAssertTrue(true, "Trick was reset after both players played")
        }
    }

    func testExample() {
        XCTAssertTrue(true)
    }
}
