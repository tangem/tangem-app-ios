//
//  PolymarketEventDetailsContentTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket event details mapping")
struct PolymarketEventDetailsContentTests {
    @Test("Markets follow the order the backend gave them")
    func explicitOrderIsFollowed() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "c", orderIndex: 2),
            Self.makeMarket(id: "a", orderIndex: 0),
            Self.makeMarket(id: "b", orderIndex: 1),
        ])

        #expect(content.activeMarkets.map(\.id) == ["a", "b", "c"])
    }

    @Test("An event that carries no order keeps the order it arrived in")
    func missingOrderKeepsArrival() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "first", orderIndex: nil),
            Self.makeMarket(id: "second", orderIndex: nil),
            Self.makeMarket(id: "third", orderIndex: nil),
        ])

        #expect(content.activeMarkets.map(\.id) == ["first", "second", "third"])
    }

    @Test("An order present on some markets never reshuffles the ones without it")
    func partialOrderKeepsArrival() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "a", orderIndex: 100),
            Self.makeMarket(id: "b", orderIndex: nil),
            Self.makeMarket(id: "c", orderIndex: nil),
        ])

        #expect(content.activeMarkets.map(\.id) == ["a", "b", "c"])
    }

    @Test("Closed markets are split out and show no outcomes")
    func closedMarketsAreSplitOut() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "open", status: .active),
            Self.makeMarket(id: "closed", status: .closed),
            Self.makeMarket(id: "archived", status: .archived),
        ])

        #expect(content.activeMarkets.map(\.id) == ["open"])
        #expect(content.closedMarkets.map(\.id) == ["closed", "archived"])
        #expect(content.closedMarkets.allSatisfy { $0.outcomes.isEmpty })
    }

    @Test("An open market that stopped taking orders offers no outcome to tap")
    func aMarketNotTakingOrdersOffersNoOutcome() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "taking", isAcceptingOrders: true),
            Self.makeMarket(id: "paused", isAcceptingOrders: false),
        ])

        #expect(content.activeMarkets.map(\.id) == ["taking", "paused"])
        #expect(content.activeMarkets.first { $0.id == "taking" }?.outcomes.isEmpty == false)
        #expect(content.activeMarkets.first { $0.id == "paused" }?.outcomes.isEmpty == true)
    }
}

// MARK: - Fixtures

private extension PolymarketEventDetailsContentTests {
    static func makeContent(markets: [PolymarketMarket]) -> PolymarketEventDetailsContent {
        .make(event: makeEvent(markets: markets), category: nil, onSelectOutcome: { _, _ in })
    }

    static func makeMarket(
        id: String,
        status: PolymarketEventStatus = .active,
        isAcceptingOrders: Bool = true,
        orderIndex: Int? = nil
    ) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            conditionId: nil,
            title: id,
            groupItemTitle: nil,
            imageURL: nil,
            iconURL: nil,
            status: status,
            isNegRisk: false,
            isAcceptingOrders: isAcceptingOrders,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            orderIndex: orderIndex,
            outcomes: [
                PolymarketOutcome(assetId: "\(id)-yes", title: "Yes", probability: 0.6),
                PolymarketOutcome(assetId: "\(id)-no", title: "No", probability: 0.4),
            ]
        )
    }

    static func makeEvent(markets: [PolymarketMarket]) -> PolymarketEvent {
        PolymarketEvent(
            id: "event",
            slug: "event",
            title: "Title",
            description: nil,
            rulesURL: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isLive: false,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            totalMarketsCount: markets.count,
            isNegRisk: false,
            displayMode: .plainMarkets,
            markets: markets
        )
    }
}
