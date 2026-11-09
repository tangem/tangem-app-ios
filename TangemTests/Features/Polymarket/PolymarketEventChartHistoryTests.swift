//
//  PolymarketEventChartHistoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket event chart history")
struct PolymarketEventChartHistoryTests {
    @Test("A young event that is not live opens on MAX, asked from the market's start on a fine grid")
    func aYoungEventOpensOnAFineMaxChart() throws {
        let start = Self.now.addingTimeInterval(-Constants.hour * 7)
        let content = try #require(Self.content(market: Self.market(startDate: start), status: .active, isLive: false))

        #expect(content.initialInterval == .allTime)
        #expect(content.intervals == [.hour, .sixHours, .allTime])
        #expect(content.historyQuery(for: .allTime, now: Self.now).matches(.range(start: start, end: nil), fidelityMinutes: 5))
    }

    @Test("A live event opens on the live window, asked as a one-hour interval on a one-minute grid")
    func aLiveEventOpensOnTheLiveWindow() throws {
        let start = Self.now.addingTimeInterval(-Constants.day * 3)
        let content = try #require(Self.content(market: Self.market(startDate: start), status: .active, isLive: true))

        #expect(content.initialInterval == .hour)
        #expect(content.historyQuery(for: content.initialInterval, now: Self.now).matches(.interval(.hour), fidelityMinutes: 1))
    }

    @Test("A ten-day-old event asks its fixed windows on Polymarket's grid")
    func aWindowUsesPolymarketsGrid() throws {
        let start = Self.now.addingTimeInterval(-Constants.day * 10)
        let content = try #require(Self.content(market: Self.market(startDate: start), status: .active, isLive: false))

        #expect(content.intervals == [.hour, .sixHours, .day, .week, .allTime])
        #expect(content.historyQuery(for: .day, now: Self.now).matches(.interval(.day), fidelityMinutes: 5))
        #expect(content.historyQuery(for: .week, now: Self.now).matches(.interval(.week), fidelityMinutes: 30))
    }

    @Test("A short market closed long ago is charted between its start and its close")
    func aClosedShortMarketIsBoundedByItsClose() throws {
        let start = Self.now.addingTimeInterval(-Constants.day * 60)
        let closedDate = start.addingTimeInterval(Constants.day * 6 + Constants.hour * 7)
        let market = Self.market(startDate: start, endDate: closedDate.addingTimeInterval(Constants.day * 7), closedDate: closedDate)
        let content = try #require(Self.content(market: market, status: .closed, isLive: false))

        #expect(content.intervals == [.allTime])
        #expect(content.historyQuery(for: .allTime, now: Self.now).matches(.range(start: start, end: closedDate), fidelityMinutes: 30))
    }

    @Test("A closed market without a close time sizes its grid to the scheduled end and leaves the end open")
    func aClosedMarketWithoutCloseTimeUsesTheScheduledEnd() throws {
        let start = Self.now.addingTimeInterval(-Constants.day * 60)
        let market = Self.market(startDate: start, endDate: start.addingTimeInterval(Constants.day * 2), closedDate: nil)
        let content = try #require(Self.content(market: market, status: .closed, isLive: false))

        #expect(content.historyQuery(for: .allTime, now: Self.now).matches(.range(start: start, end: nil), fidelityMinutes: 15))
    }

    @Test("Refreshed probabilities keep the market's lifetime")
    func refreshingKeepsTheLifetime() throws {
        let start = Self.now.addingTimeInterval(-Constants.hour * 7)
        let market = Self.market(startDate: start)
        let event = Self.event(market: market, status: .active, isLive: false)
        let content = try #require(Self.content(market: market, status: .active, isLive: false))

        #expect(content.refreshed(from: event).lifetime == content.lifetime)
    }
}

// MARK: - Fixtures

private extension PolymarketEventChartHistoryTests {
    static let now = Date(timeIntervalSince1970: 1_792_668_524)

    static func market(startDate: Date, endDate: Date? = nil, closedDate: Date? = nil) -> PolymarketMarket {
        PolymarketMarket(
            id: "market",
            conditionId: nil,
            title: "Team A vs Team B",
            groupItemTitle: nil,
            imageURL: nil,
            iconURL: nil,
            status: closedDate == nil ? .active : .closed,
            isNegRisk: false,
            isAcceptingOrders: closedDate == nil,
            startDate: startDate,
            endDate: endDate,
            closedDate: closedDate,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            orderIndex: nil,
            outcomes: [
                PolymarketOutcome(assetId: "first", title: "Team A", probability: 0.6),
                PolymarketOutcome(assetId: "second", title: "Team B", probability: 0.4),
            ]
        )
    }

    static func event(market: PolymarketMarket, status: PolymarketEventStatus, isLive: Bool) -> PolymarketEvent {
        PolymarketEvent(
            id: "event",
            slug: "event",
            title: "Team A vs Team B",
            description: nil,
            rulesURL: nil,
            imageURL: nil,
            iconURL: nil,
            status: status,
            isLive: isLive,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            totalMarketsCount: 1,
            isNegRisk: false,
            displayMode: .plainMarkets,
            markets: [market]
        )
    }

    static func content(market: PolymarketMarket, status: PolymarketEventStatus, isLive: Bool) -> PolymarketEventChartContent? {
        PolymarketEventChartContent.make(
            event: event(market: market, status: status, isLive: isLive),
            marketIDs: [market.id],
            sports: nil,
            now: now
        )
    }

    enum Constants {
        static let hour: TimeInterval = 60 * 60
        static let day: TimeInterval = 24 * 60 * 60
    }
}

// MARK: - Matching

private extension PolymarketPriceHistoryQuery {
    func matches(_ window: Window, fidelityMinutes: Int) -> Bool {
        self.window == window && self.fidelityMinutes == fidelityMinutes
    }
}
