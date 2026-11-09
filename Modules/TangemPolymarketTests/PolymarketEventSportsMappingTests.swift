//
//  PolymarketEventSportsMappingTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket event sports mapping")
struct PolymarketEventSportsMappingTests {
    @Test("A game tagged as sports names its moneyline markets and nothing else")
    func sportsEventKeepsOnlyTheMoneyline() throws {
        let sports = try Self.map("""
        {
          "tags": [{ "slug": "esports" }, { "slug": "games" }, { "slug": "sports" }],
          "markets": [
            { "conditionId": "0xmatch", "sportsMarketType": "moneyline" },
            { "conditionId": "0xmap1", "sportsMarketType": "child_moneyline" },
            { "conditionId": "0xtotal", "sportsMarketType": "totals" },
            { "conditionId": "0xhandicap", "sportsMarketType": "map_handicap" }
          ]
        }
        """)

        #expect(sports.isSports)
        #expect(sports.moneylineConditionIds == ["0xmatch"])
    }

    @Test("A three-way game keeps every one of its moneyline markets")
    func threeWayGameKeepsEveryMoneyline() throws {
        let sports = try Self.map("""
        {
          "tags": [{ "slug": "sports" }, { "slug": "soccer" }],
          "markets": [
            { "conditionId": "0xhome", "sportsMarketType": "moneyline" },
            { "conditionId": "0xdraw", "sportsMarketType": "moneyline" },
            { "conditionId": "0xaway", "sportsMarketType": "moneyline" }
          ]
        }
        """)

        #expect(sports.moneylineConditionIds == ["0xhome", "0xdraw", "0xaway"])
    }

    @Test("Moneyline condition ids are kept in lower case so they match the BFF markets whatever case Gamma sends")
    func moneylineConditionIdsAreLowercased() throws {
        let sports = try Self.map("""
        {
          "tags": [{ "slug": "sports" }],
          "markets": [{ "conditionId": "0xABCdef", "sportsMarketType": "moneyline" }]
        }
        """)

        #expect(sports.moneylineConditionIds == ["0xabcdef"])
    }

    @Test("An event without the sports tag is not a game, whatever its markets say")
    func untaggedEventIsNotSports() throws {
        let sports = try Self.map("""
        {
          "tags": [{ "slug": "politics" }],
          "markets": [{ "conditionId": "0xa" }]
        }
        """)

        #expect(!sports.isSports)
        #expect(sports.moneylineConditionIds.isEmpty)
    }

    @Test("Missing tags and markets read as a plain event")
    func emptyAnswerIsAPlainEvent() throws {
        let sports = try Self.map("{}")

        #expect(!sports.isSports)
        #expect(sports.moneylineConditionIds.isEmpty)
    }
}

// MARK: - Helpers

private extension PolymarketEventSportsMappingTests {
    static func map(_ json: String) throws -> PolymarketEventSports {
        let dto = try JSONDecoder().decode(PolymarketDTO.EventSports.self, from: Data(json.utf8))

        return PolymarketMapper().mapEventSports(dto)
    }
}
