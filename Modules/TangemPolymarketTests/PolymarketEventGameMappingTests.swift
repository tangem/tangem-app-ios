//
//  PolymarketEventGameMappingTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket event game mapping")
struct PolymarketEventGameMappingTests {
    @Test("The game of an event keeps its id, score, period and end")
    func gameIsMapped() throws {
        let game = try #require(try mapEvent(game: #""gameId": "20023885", "score": "98-101", "period": "Q4", "ended": true"#).game)

        #expect(game == PolymarketEventGame(
            gameId: "20023885",
            score: .points(PolymarketGameScore.Points(first: 98, second: 101)),
            period: "Q4",
            hasEnded: true
        ))
    }

    @Test("An event whose game id is empty or blank has no game", arguments: [#""gameId": """#, #""gameId": "   ""#])
    func blankGameIdMeansNoGame(_ fields: String) throws {
        #expect(try mapEvent(game: fields).game == nil)
    }
}

// MARK: - Helpers

private extension PolymarketEventGameMappingTests {
    func mapEvent(game fields: String) throws -> PolymarketEvent {
        let json = """
        {"eventId": "1197295", "slug": "nba-cle-phi-2026-10-22", "title": "Cavaliers vs. 76ers", "live": true, \(fields)}
        """
        let dto = try JSONDecoder().decode(PolymarketDTO.Event.self, from: Data(json.utf8))

        return PolymarketMapper().mapEvent(dto)
    }
}
