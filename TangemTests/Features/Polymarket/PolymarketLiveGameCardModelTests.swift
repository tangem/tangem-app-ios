//
//  PolymarketLiveGameCardModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
import TangemPolymarketUI
@testable import Tangem

@Suite("Polymarket live game card")
struct PolymarketLiveGameCardModelTests {
    private typealias Fixtures = PolymarketLiveGamesFixtures

    @Test("A tennis match shows the sets each player has won, not the games of a set still being played", arguments: [
        WonSets(score: "6-4, 4-6, 8-7", home: "1", away: "1"),
        WonSets(score: "6-7(4-7), 6-2, 0-2", home: "1", away: "1"),
        WonSets(score: "7-5, 6-6", home: "1", away: "0"),
        WonSets(score: "6-3, 3-6, 10-8", home: "2", away: "1"),
    ])
    func tennisShowsWonSets(_ row: WonSets) throws {
        let card = try #require(makeCard(Fixtures.tennis(score: row.score)))

        #expect(card.score == PolymarketLiveGameCard.Score(home: row.home, away: row.away))
    }

    @Test("An NBA score, the guest first like the teams, puts every number at its own team")
    func guestFirstScoreLandsOnItsTeams() throws {
        let card = try #require(makeCard(Fixtures.basketball(score: "98-101")))

        #expect(card.home.name == "76ers")
        #expect(card.score == PolymarketLiveGameCard.Score(home: "101", away: "98"))
    }

    @Test("Buttons go home, draw, away, with the team abbreviations of both teams")
    func soccerButtonsFollowTheSides() throws {
        let card = try #require(makeCard(Fixtures.soccer()))

        #expect(card.outcomes.map(\.title) == ["ARS", "Draw", "CHE"])
        #expect(card.outcomes.map(\.id) == ["1201001-ars-yes", "1201001-draw-yes", "1201001-che-yes"])
        #expect(card.outcomes.map(\.style) == [.affirmative, .neutral, .negative])
    }

    @Test("A match that has not started stays on the regular card")
    func matchBeforeTheStartHasNoLiveCard() {
        #expect(makeCard(Fixtures.basketball(isLive: false, score: nil, period: nil)) == nil)
    }

    struct WonSets: CustomTestStringConvertible, Sendable {
        let score: String
        let home: String
        let away: String

        var testDescription: String {
            "\(score) → \(home) : \(away)"
        }
    }
}

// MARK: - Helpers

private extension PolymarketLiveGameCardModelTests {
    func makeCard(_ event: PolymarketEvent) -> PolymarketLiveGameCard.Model? {
        .make(event: event, liveGame: nil, liveQuotesByAssetId: [:], onSelectOutcome: { _, _ in })
    }
}
