//
//  PolymarketEventChartSessionTests.swift
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

@Suite("Polymarket event chart session")
struct PolymarketEventChartSessionTests {
    @Test("A live event opens on the live window and shows the chart once its history arrives")
    func firstHistoryIsShown() throws {
        var session = try Self.loadedSession(isLive: true)

        #expect(session.selectedInterval == .hour)
        #expect(!session.isLoadingHistory)
        #expect(session.displayedHistory?.interval == .hour)

        let model = try #require(Self.model(session))
        #expect(model.periods?.selectedID == PolymarketPriceInterval.hour.rawValue)
        #expect(!model.isLoading)

        session.startLoading(.hour)
        #expect(session.isLoadingHistory)
    }

    @Test("A period switch that fails goes back to the period still on screen")
    func failedSwitchGoesBack() throws {
        var session = try Self.loadedSession(isLive: false)

        let switchesToHour = session.selectPeriod(.hour, now: Self.now)
        #expect(switchesToHour)
        #expect(try #require(Self.model(session)).isLoading)
        #expect(session.selectedInterval == .hour)

        session.applyHistory(nil, interval: .hour, fidelityMinutes: 1, now: Self.now)

        #expect(session.selectedInterval == .allTime)
        #expect(session.displayedHistory?.interval == .allTime)
        #expect(!session.isLoadingHistory)
        #expect(try #require(Self.model(session)).periods?.selectedID == PolymarketPriceInterval.allTime.rawValue)
        #expect(try #require(Self.model(session)).isLoading == false)
    }

    @Test("History of a period the user already left is dropped")
    func historyOfALeftPeriodIsDropped() throws {
        var session = try Self.loadedSession(isLive: false)

        let switchesToHour = session.selectPeriod(.hour, now: Self.now)
        #expect(switchesToHour)
        let switchesToSixHours = session.selectPeriod(.sixHours, now: Self.now)
        #expect(switchesToSixHours)

        session.applyHistory(Self.history(), interval: .hour, fidelityMinutes: 1, now: Self.now)

        #expect(session.displayedHistory?.interval == .allTime)
        #expect(session.loadingInterval == .sixHours)
    }

    @Test("Coming back to a loaded period shows it at once and refreshes it without dimming the chart")
    func cachedPeriodIsShownAtOnce() throws {
        var session = try Self.loadedSession(isLive: false)

        let switchesToHour = session.selectPeriod(.hour, now: Self.now)
        #expect(switchesToHour)
        session.applyHistory(Self.history(), interval: .hour, fidelityMinutes: 1, now: Self.now)

        let switchesBack = session.selectPeriod(.allTime, now: Self.now)
        #expect(switchesBack)

        #expect(session.displayedHistory?.interval == .allTime)
        #expect(session.loadingInterval == .allTime)
        #expect(try #require(Self.model(session)).isLoading == false)
    }

    @Test("The selected period or one the event does not offer is not asked for")
    func unavailablePeriodIsIgnored() throws {
        var session = try Self.loadedSession(isLive: false)

        let reselectsCurrent = session.selectPeriod(.allTime, now: Self.now)
        #expect(!reselectsCurrent)
        let selectsUnoffered = session.selectPeriod(.month, now: Self.now)
        #expect(!selectsUnoffered)
        #expect(!session.isLoadingHistory)
    }

    @Test("A live chart keeps following the price between polls")
    func liveChartFollowsPolls() throws {
        var session = try Self.loadedSession(isLive: true)

        let reloadsAfterTenSeconds = session.refresh(with: Self.event(isLive: true), now: Self.now.addingTimeInterval(10))
        #expect(!reloadsAfterTenSeconds)
        let reloadsAfterTwentySeconds = session.refresh(with: Self.event(isLive: true), now: Self.now.addingTimeInterval(20))
        #expect(!reloadsAfterTwentySeconds)

        let model = try #require(Self.model(session, now: Self.now.addingTimeInterval(20)))
        #expect(model.latestMarker == .pulsing)
        #expect(!session.isLoadingHistory)
    }

    @Test("A live chart left alone longer than its grid step reloads its history instead of drawing over the gap")
    func liveChartReloadsAfterAGap() throws {
        var session = try Self.loadedSession(isLive: true)

        let reloadsAfterAnHour = session.refresh(with: Self.event(isLive: true), now: Self.now.addingTimeInterval(Self.hour))
        #expect(reloadsAfterAnHour)

        #expect(session.loadingInterval == .hour)
        #expect(try #require(Self.model(session, now: Self.now.addingTimeInterval(Self.hour))).isLoading)
    }

    @Test("A chart that is not live reloads once its grid step has passed")
    func chartReloadsAfterItsGridStep() throws {
        var session = try Self.loadedSession(isLive: false, fidelityMinutes: 5)

        let reloadsAfterAMinute = session.refresh(with: Self.event(isLive: false), now: Self.now.addingTimeInterval(60))
        #expect(!reloadsAfterAMinute)
        let reloadsAfterFiveMinutes = session.refresh(with: Self.event(isLive: false), now: Self.now.addingTimeInterval(5 * 60))
        #expect(reloadsAfterFiveMinutes)
        #expect(session.loadingInterval == .allTime)
    }

    @Test("A poll while history is loading changes nothing")
    func pollDuringLoadingIsIgnored() throws {
        var session = try Self.loadedSession(isLive: false)
        session.startLoading(.allTime)

        let reloadsWhileLoading = session.refresh(with: Self.event(isLive: false, probability: 0.9), now: Self.now.addingTimeInterval(Self.hour))
        #expect(!reloadsWhileLoading)
        #expect(session.content.outcomes.first?.probability == 0.5)
    }
}

// MARK: - Fixtures

private extension PolymarketEventChartSessionTests {
    static let now = Date(timeIntervalSince1970: 1_792_674_084)
    static let hour: TimeInterval = 60 * 60
    static let tokenID = "market-yes"

    static func loadedSession(isLive: Bool, fidelityMinutes: Int = 1) throws -> PolymarketEventChartSession {
        let content = try #require(PolymarketEventChartContent.make(event: event(isLive: isLive), marketIDs: ["market"], sports: nil, now: now))
        var session = PolymarketEventChartSession(content: content)

        session.startLoading(session.selectedInterval)
        session.applyHistory(history(), interval: session.selectedInterval, fidelityMinutes: fidelityMinutes, now: now)

        return session
    }

    static func model(_ session: PolymarketEventChartSession, now: Date = now) -> PolymarketProbabilityChart.Model? {
        session.chartModel(now: now, legendLineCount: 1, animatesChanges: false, onSelectPeriod: { _ in })
    }

    static func history() -> [String: [PolymarketPricePoint]] {
        [tokenID: [
            PolymarketPricePoint(date: now.addingTimeInterval(-hour / 2), probability: 0.4),
            PolymarketPricePoint(date: now.addingTimeInterval(-60), probability: 0.5),
        ]]
    }

    static func event(isLive: Bool, probability: Decimal = 0.5) -> PolymarketEvent {
        let market = PolymarketMarket(
            id: "market",
            conditionId: nil,
            title: "Will it rain?",
            groupItemTitle: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isNegRisk: false,
            isAcceptingOrders: true,
            startDate: now.addingTimeInterval(-hour * 24 * 3),
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            orderIndex: nil,
            outcomes: [
                PolymarketOutcome(assetId: tokenID, title: "Yes", probability: probability),
                PolymarketOutcome(assetId: "market-no", title: "No", probability: 1 - probability),
            ]
        )

        return PolymarketEvent(
            id: "event",
            slug: "event",
            title: "Will it rain?",
            description: nil,
            rulesURL: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
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
}
