//
//  PolymarketMarketVersionTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket market version")
struct PolymarketMarketVersionTests {
    private let mapper = PolymarketMapper()

    @Test("A market's version is read without ever failing the page", arguments: [
        (#""version": "v1","#, PolymarketMarketVersion.v1, true),
        (#""version": "v2","#, PolymarketMarketVersion.v2, true),
        (#""version": "v7","#, PolymarketMarketVersion.unknown("v7"), false),
        (#""version": "unknown","#, PolymarketMarketVersion.unknown("unknown"), false),
        ("", PolymarketMarketVersion.unknown(nil), false),
    ])
    func marketVersion(_ field: String, _ expected: PolymarketMarketVersion, _ tradable: Bool) throws {
        let market = try mapMarket(versionField: field)

        #expect(market.version == expected)
        #expect(market.isAcceptingOrders == tradable)
    }

    @Test("A migrated outcome keeps its old token for matching, a native one has none")
    func legacyAssetId() throws {
        let market = try mapMarket(versionField: #""version": "v2","#)

        #expect(market.outcomes.map(\.assetId) == ["895257305792", "895257305793"])
        #expect(market.outcomes.map(\.legacyAssetId) == ["1062291234", nil])
    }

    @Test("A position's version is read, and an unknown one closes selling", arguments: [
        (#""version": "v1","#, PolymarketMarketVersion?.some(.v1), true),
        (#""version": "v2","#, PolymarketMarketVersion?.some(.v2), true),
        (#""version": "v9","#, PolymarketMarketVersion?.some(.unknown("v9")), false),
        (#""version": null,"#, PolymarketMarketVersion?.none, true),
        ("", PolymarketMarketVersion?.none, true),
    ])
    func positionVersion(_ field: String, _ expected: PolymarketMarketVersion?, _ tradable: Bool) throws {
        let json = """
        { "positions": [{ "conditionId": "0x1", "assetId": "2", \(field) "acceptingOrders": true }] }
        """
        let dto = try JSONDecoder().decode(PolymarketDTO.PositionsResponse.self, from: Data(json.utf8))
        let position = try #require(mapper.mapPositions(dto).positions.first)

        #expect(position.version == expected)
        #expect(position.isAcceptingOrders == tradable)
    }

    private func mapMarket(versionField: String) throws -> PolymarketMarket {
        let json = """
        {
          "id": "559651",
          "question": "Will it rain?",
          "conditionId": "0xabc",
          \(versionField)
          "acceptingOrders": true,
          "outcomes": [
            { "assetId": "895257305792", "legacyAssetId": "1062291234", "label": "Yes", "probability": 0.12 },
            { "assetId": "895257305793", "legacyAssetId": null, "label": "No", "probability": 0.88 }
          ]
        }
        """

        return try mapper.mapMarket(JSONDecoder().decode(PolymarketDTO.Market.self, from: Data(json.utf8)))
    }
}

// MARK: - Matching a position to its market

@Suite("Polymarket position market match")
struct PolymarketPositionMarketMatchTests {
    @Test("The market is found by id and the outcome by index")
    func matchesByIdAndIndex() throws {
        let match = try #require(Self.position(marketId: "m2", outcomeIndex: 1).marketMatch(in: Self.markets))

        #expect(match.market.id == "m2")
        #expect(match.outcome.assetId == "v2-no")
    }

    @Test("Without a market id the condition finds the market, in any casing")
    func matchesByCondition() throws {
        let position = Self.position(marketId: nil, conditionId: "0XC2", outcomeIndex: 0)
        let match = try #require(position.marketMatch(in: Self.markets))

        #expect(match.market.id == "m2")
        #expect(match.outcome.assetId == "v2-yes")
    }

    @Test("An old CTF token on a market moved to V2 still finds its outcome by index")
    func legacyTokenMatchesByIndex() throws {
        let position = Self.position(assetId: "ctf-no", marketId: "m2", outcomeIndex: 1)
        let match = try #require(position.marketMatch(in: Self.markets))

        #expect(match.outcome.assetId == "v2-no")
        #expect(match.outcome.legacyAssetId == "ctf-no")
        #expect(!position.isTradable(as: match.outcome))
    }

    @Test("Without an index the old CTF token is recognised through the legacy id")
    func legacyTokenMatchesByLegacyId() throws {
        let position = Self.position(assetId: "ctf-no", marketId: nil, conditionId: "0xgone", outcomeIndex: nil)
        let match = try #require(position.marketMatch(in: Self.markets))

        #expect(match.market.id == "m2")
        #expect(match.outcome.assetId == "v2-no")
    }

    @Test("Without an index the current token is recognised directly")
    func currentTokenMatchesByAssetId() throws {
        let position = Self.position(assetId: "v1-yes", marketId: "m1", outcomeIndex: nil)
        let match = try #require(position.marketMatch(in: Self.markets))

        #expect(match.market.id == "m1")
        #expect(match.outcome.assetId == "v1-yes")
    }

    @Test("An index outside the market falls back to the token")
    func outOfRangeIndexFallsBack() throws {
        let position = Self.position(assetId: "v1-no", marketId: "m1", outcomeIndex: 5)
        let match = try #require(position.marketMatch(in: Self.markets))

        #expect(match.outcome.assetId == "v1-no")
    }

    @Test("A position of a market the event does not hold matches nothing")
    func foreignPositionMatchesNothing() {
        let position = Self.position(assetId: "elsewhere", marketId: "m9", conditionId: "0xc9", outcomeIndex: 0)

        #expect(position.marketMatch(in: Self.markets) == nil)
    }
}

private extension PolymarketPositionMarketMatchTests {
    static let markets = [
        market(id: "m1", conditionId: "0xc1", version: .v1, outcomes: [
            PolymarketOutcome(assetId: "v1-yes", title: "Yes", probability: nil),
            PolymarketOutcome(assetId: "v1-no", title: "No", probability: nil),
        ]),
        market(id: "m2", conditionId: "0xc2", version: .v2, outcomes: [
            PolymarketOutcome(assetId: "v2-yes", legacyAssetId: "ctf-yes", title: "Yes", probability: nil),
            PolymarketOutcome(assetId: "v2-no", legacyAssetId: "ctf-no", title: "No", probability: nil),
        ]),
    ]

    static func market(
        id: String,
        conditionId: String,
        version: PolymarketMarketVersion,
        outcomes: [PolymarketOutcome]
    ) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            conditionId: conditionId,
            version: version,
            title: id,
            groupItemTitle: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isNegRisk: false,
            isAcceptingOrders: true,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            orderIndex: nil,
            outcomes: outcomes
        )
    }

    static func position(
        assetId: String = "v2-no",
        marketId: String?,
        conditionId: String = "0xc2",
        outcomeIndex: Int?
    ) -> PolymarketPosition {
        PolymarketPosition(
            conditionId: conditionId,
            assetId: assetId,
            marketId: marketId,
            eventId: "e1",
            eventTitle: nil,
            title: "",
            iconURL: nil,
            endDate: nil,
            outcome: "",
            outcomeIndex: outcomeIndex,
            size: 1,
            avgPrice: 0,
            curPrice: 0,
            initialValue: 0,
            currentValue: 0,
            cashPnl: 0,
            pnlRatio: 0,
            realizedPnl: 0,
            isRedeemable: false,
            isNegRisk: false,
            isAcceptingOrders: true,
            isLive: false,
            resolutionStatus: .open,
            settlement: nil
        )
    }
}
