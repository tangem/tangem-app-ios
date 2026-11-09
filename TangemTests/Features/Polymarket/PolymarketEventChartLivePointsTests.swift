//
//  PolymarketEventChartLivePointsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Testing
import TangemPolymarket
import TangemPolymarketUI
@testable import Tangem

@Suite("Polymarket event chart live points")
struct PolymarketEventChartLivePointsTests {
    @Test("On the live window every poll adds a point after the ones already followed")
    func liveWindowKeepsEveryPoll() throws {
        let content = try #require(Self.content(status: .active, isLive: true))

        let first = content.recordingLivePoints([:], interval: .hour, at: Self.now)
        let second = content.recordingLivePoints(first, interval: .hour, at: Self.now.addingTimeInterval(10))

        #expect(second[Constants.tokenID]?.map(\.date) == [Self.now, Self.now.addingTimeInterval(10)])
    }

    @Test("Outside the live window a poll only moves the latest point")
    func otherWindowsKeepOnlyTheLatestPoint() throws {
        let content = try #require(Self.content(status: .active, isLive: true))

        let first = content.recordingLivePoints([:], interval: .day, at: Self.now)
        let second = content.recordingLivePoints(first, interval: .day, at: Self.now.addingTimeInterval(10))

        #expect(second[Constants.tokenID]?.map(\.date) == [Self.now.addingTimeInterval(10)])
    }

    @Test("A closed event follows no price")
    func closedEventFollowsNoPrice() throws {
        let content = try #require(Self.content(status: .closed, isLive: false))

        #expect(content.recordingLivePoints([:], interval: .allTime, at: Self.now).isEmpty)
    }

    @Test("The live tail continues the history and drops what fell out of the window")
    func liveTailContinuesTheHistory() {
        let history = Self.series(at: [-Constants.hour - 60, -120, -60])
        let live = [Constants.tokenID: [Self.point(at: -30), Self.point(at: 0)]]

        let series = PolymarketEventChartContent.seriesWithLivePoints([history], livePoints: live, interval: .hour, now: Self.now)

        #expect(series.first?.points.map(\.date) == [-120, -60, -30, 0].map { Self.now.addingTimeInterval($0) })
    }

    @Test("History that fell out of the window is drawn as it is until the live tail has a line of its own")
    func staleHistoryIsKeptUntilTheTailIsALine() {
        let history = Self.series(at: [-Constants.hour * 3, -Constants.hour * 2])
        let live = [Constants.tokenID: [Self.point(at: 0)]]

        let series = PolymarketEventChartContent.seriesWithLivePoints([history], livePoints: live, interval: .hour, now: Self.now)

        #expect(series.first?.points == history.points)
    }

    @Test("A chart followed for less than one grid step is fresh, a longer gap is outdated", arguments: [
        (59.0, false),
        (60.0, true),
        (Constants.hour, true),
    ])
    func outdatedAfterOneGridStep(gap: TimeInterval, isOutdated: Bool) {
        let lastUpdate = Self.now.addingTimeInterval(-gap)

        #expect(PolymarketEventChartContent.isOutdated(since: lastUpdate, fidelityMinutes: 1, now: Self.now) == isOutdated)
    }
}

// MARK: - Fixtures

private extension PolymarketEventChartLivePointsTests {
    enum Constants {
        static let tokenID = "market-yes"
        static let hour: TimeInterval = 60 * 60
    }

    static let now = Date(timeIntervalSince1970: 1_792_674_084)

    static func point(at offset: TimeInterval) -> PolymarketProbabilityChart.Point {
        PolymarketProbabilityChart.Point(date: now.addingTimeInterval(offset), probability: 0.5)
    }

    static func series(at offsets: [TimeInterval]) -> PolymarketProbabilityChart.Series {
        PolymarketProbabilityChart.Series(
            id: Constants.tokenID,
            title: "Yes",
            probabilityText: "50%",
            color: .blue,
            points: offsets.map(point(at:))
        )
    }

    static func content(status: PolymarketEventStatus, isLive: Bool) -> PolymarketEventChartContent? {
        let market = PolymarketMarket(
            id: "market",
            conditionId: nil,
            title: "Will it rain?",
            groupItemTitle: nil,
            imageURL: nil,
            iconURL: nil,
            status: status,
            isNegRisk: false,
            isAcceptingOrders: status != .closed,
            startDate: now.addingTimeInterval(-Constants.hour * 24 * 3),
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            orderIndex: nil,
            outcomes: [
                PolymarketOutcome(assetId: Constants.tokenID, title: "Yes", probability: 0.5),
                PolymarketOutcome(assetId: "market-no", title: "No", probability: 0.5),
            ]
        )

        let event = PolymarketEvent(
            id: "event",
            slug: "event",
            title: "Will it rain?",
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

        return PolymarketEventChartContent.make(event: event, marketIDs: [market.id], sports: nil, now: now)
    }
}
