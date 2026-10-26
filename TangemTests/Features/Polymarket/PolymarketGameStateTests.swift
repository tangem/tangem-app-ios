//
//  PolymarketGameStateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket game state")
struct PolymarketGameStateTests {
    private typealias Fixtures = PolymarketLiveGamesFixtures

    @Test("Whether a match is on and shows the Live badge", arguments: Row.all)
    func liveAndBadge(_ row: Row) throws {
        let state = try #require(PolymarketGameState(event: row.event, liveGame: row.liveGame))

        #expect(state.isLive == row.isLive)
        #expect(state.hasEnded == row.hasEnded)
        #expect(state.showsLiveBadge == row.showsLiveBadge)
    }

    @Test("On the same stage the score and period come from the socket")
    func socketWinsOnTheSameStage() throws {
        let liveGame = Fixtures.liveGame("20023885", score: "100-101", period: "Q4")
        let state = try #require(PolymarketGameState(event: Fixtures.basketball(isLive: true, score: "98-101", period: "Q3"), liveGame: liveGame))

        #expect(state.score == liveGame.score)
        #expect(state.period == "Q4")
    }

    @Test("A socket behind REST does not roll the score back")
    func socketBehindRestKeepsTheRestScore() throws {
        let event = Fixtures.basketball(isLive: true, score: "98-101", period: "Q4")
        let state = try #require(PolymarketGameState(event: event, liveGame: Fixtures.liveGame("20023885", score: "0-0", period: nil, isLive: false)))

        #expect(state.score == event.game?.score)
        #expect(state.period == "Q4")
    }

    @Test("An event without a game has no game state")
    func eventWithoutGame() {
        let event = Fixtures.event(id: "e", title: "Will it rain?", isLive: true, markets: [], teams: [], game: nil)

        #expect(PolymarketGameState(event: event, liveGame: nil) == nil)
    }

    struct Row: CustomTestStringConvertible, Sendable {
        let testDescription: String
        let event: PolymarketEvent
        let liveGame: PolymarketLiveGame?
        let isLive: Bool
        let hasEnded: Bool
        let showsLiveBadge: Bool

        static let all: [Row] = [
            Row(
                testDescription: "live in REST",
                event: Fixtures.basketball(isLive: true),
                liveGame: nil,
                isLive: true,
                hasEnded: false,
                showsLiveBadge: true
            ),
            Row(
                testDescription: "ended in REST while the event still says live",
                event: Fixtures.basketball(isLive: true, period: "FT", hasEnded: true),
                liveGame: nil,
                isLive: false,
                hasEnded: true,
                showsLiveBadge: false
            ),
            Row(
                testDescription: "started on the socket before REST knows",
                event: Fixtures.basketball(isLive: false, score: nil, period: nil),
                liveGame: Fixtures.liveGame("20023885", score: "2-0", period: "Q1"),
                isLive: true,
                hasEnded: false,
                showsLiveBadge: true
            ),
            Row(
                testDescription: "ended on the socket",
                event: Fixtures.basketball(isLive: true),
                liveGame: Fixtures.liveGame("20023885", score: "110-104", period: "FT", isLive: false, hasEnded: true),
                isLive: false,
                hasEnded: true,
                showsLiveBadge: false
            ),
            Row(
                testDescription: "not started on the socket while REST says live",
                event: Fixtures.basketball(isLive: true),
                liveGame: Fixtures.liveGame("20023885", score: nil, period: nil, isLive: false),
                isLive: true,
                hasEnded: false,
                showsLiveBadge: true
            ),
            Row(
                testDescription: "still live on the socket while REST says ended",
                event: Fixtures.basketball(isLive: true, period: "FT", hasEnded: true),
                liveGame: Fixtures.liveGame("20023885", score: "110-104", period: "Q4"),
                isLive: false,
                hasEnded: true,
                showsLiveBadge: false
            ),
            Row(
                testDescription: "postponed while still flagged live",
                event: Fixtures.basketball(isLive: true, period: "post"),
                liveGame: nil,
                isLive: true,
                hasEnded: false,
                showsLiveBadge: false
            ),
        ]
    }
}
