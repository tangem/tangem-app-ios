//
//  PolymarketEventsBlockViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import UIKit
import TangemPolymarket
import TangemPolymarketUI
@testable import Tangem

@Suite("Polymarket events block")
@MainActor
struct PolymarketEventsBlockViewModelTests {
    @Test("Coming back to a visited category shows it again without asking the backend")
    func visitedCategoryComesFromCache() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = [Self.category(1), Self.category(2)]
        provider.eventPages = [
            .init(category: 1, cursor: nil): Self.page(["a"]),
            .init(category: 2, cursor: nil): Self.page(["b"]),
        ]
        let sut = Self.makeSUT(provider: provider)

        try await settle { Self.cardIDs(sut) == ["a"] }

        sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 2, title: "")
        try await settle { Self.cardIDs(sut) == ["b"] }

        sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 1, title: "")

        #expect(Self.cardIDs(sut) == ["a"])
        #expect(provider.eventsRequests.count == 2)
    }

    @Test("A page made only of events already shown asks for the next page")
    func duplicatePageLoadsTheNextOne() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = [Self.category(1)]
        provider.eventPages = [
            .init(category: 1, cursor: nil): Self.page(["a"], cursor: "c1"),
            .init(category: 1, cursor: "c1"): Self.page(["a"], cursor: "c2"),
            .init(category: 1, cursor: "c2"): Self.page(["b"]),
        ]
        let sut = Self.makeSUT(provider: provider)

        try await settle { Self.cardIDs(sut) == ["a"] }

        sut.handleViewAction(.loadNextPage)

        try await settle { Self.cardIDs(sut) == ["a", "b"] }

        #expect(provider.eventsRequests.map(\.cursor) == [nil, "c1", "c2"])
        #expect(sut.loadingState == .allDataLoaded)
    }

    @Test("A backend that keeps returning only events already shown stops being asked after a few pages")
    func endlessDuplicatePagesStop() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = [Self.category(1)]
        provider.eventPages = [
            .init(category: 1, cursor: nil): Self.page(["a"], cursor: "c1"),
            .init(category: 1, cursor: "c1"): Self.page(["a"], cursor: "c1"),
        ]
        let sut = Self.makeSUT(provider: provider)

        try await settle { Self.cardIDs(sut) == ["a"] }

        sut.handleViewAction(.loadNextPage)

        try await settle { provider.eventsRequests.count == 5 }
        try await drain()

        #expect(provider.eventsRequests.count == 5)
        #expect(sut.loadingState == .loaded)
        #expect(Self.cardIDs(sut) == ["a"])
    }

    @Test("Retrying after the categories failed to load brings the feed back")
    func retryAfterFailedCategoriesLoadsTheFeed() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.queuedCategoryResults = [.failure(EventsTestError.unavailable)]
        provider.categoryList = [Self.category(1)]
        provider.eventPages = [.init(category: 1, cursor: nil): Self.page(["a"])]
        let sut = Self.makeSUT(provider: provider)

        try await settle { sut.loadingState == .error }

        sut.handleViewAction(.retry)

        try await settle { Self.cardIDs(sut) == ["a"] }
        #expect(sut.loadingState == .allDataLoaded)
    }

    @Test("A tab picked while the retried feed is still loading shows only its own events")
    func tabPickedDuringRetryKeepsItsOwnEvents() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.queuedCategoryResults = [.failure(EventsTestError.unavailable)]
        provider.categoryList = [Self.category(1), Self.category(2)]
        provider.slowEventCategories = [1]
        provider.eventPages = [
            .init(category: 1, cursor: nil): Self.page(["a"]),
            .init(category: 2, cursor: nil): Self.page(["b"]),
        ]
        let sut = Self.makeSUT(provider: provider)

        try await settle { sut.loadingState == .error }

        sut.handleViewAction(.retry)
        try await settle { !sut.categories.isEmpty }

        sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 2, title: "")

        try await settle { Self.cardIDs(sut) == ["b"] }
        try await Task.sleep(nanoseconds: PolymarketAPIProviderStub.slowEventsDelay * 3 / 2)

        #expect(Self.cardIDs(sut) == ["b"])
    }

    @Test("Choosing an outcome in a restricted region opens the region warning instead of the order")
    func restrictedRegionOpensWarning() async throws {
        let outcome = PolymarketOutcome(assetId: "yes", title: "Yes", probability: 0.42)
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = [Self.category(1)]
        provider.eventPages = [.init(category: 1, cursor: nil): Self.page(["a"], outcomes: [outcome])]
        let routable = PolymarketEventOpeningRoutableSpy()
        let sut = Self.makeSUT(provider: provider, routable: routable, isRegionRestricted: true)

        try await settle { Self.cardIDs(sut) == ["a"] }

        let selected = try #require(sut.eventCards.first?.rows.first?.outcomes.first)
        selected.onSelect()

        #expect(routable.openedOutcomes.isEmpty)
        #expect(routable.regionWarningOpenings == 1)
        withExtendedLifetime(sut) {}
    }

    // MARK: - Polling

    @Test("A visible page older than the stale age is asked for again with its own cursor")
    func staleVisiblePageIsRefreshed() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))

        try await settle { context.provider.eventsRequests.count == 2 }
        #expect(context.provider.eventsRequests.last?.cursor == nil)
        #expect(context.provider.eventsRequests.last?.category == 1)
    }

    @Test("A fresh page and a page off screen are not asked for")
    func freshOrHiddenPagesAreNotRefreshed() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: false))
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "elsewhere", isVisible: true))
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        #expect(context.provider.eventsRequests.count == 1)

        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await settle { context.provider.eventsRequests.count == 2 }
    }

    @Test("A failed later page keeps the feed as it is and is asked again on the next tick")
    func failedLaterPageKeepsTheFeed() async throws {
        let context = try await Self.makePollingContext(pages: [
            .init(category: 1, cursor: nil): Self.page(["a"], cursor: "c1"),
            .init(category: 1, cursor: "c1"): Self.page(["b"]),
        ])

        context.sut.handleViewAction(.loadNextPage)
        try await settle { Self.cardIDs(context.sut) == ["a", "b"] }

        context.provider.eventErrors = [.init(category: 1, cursor: "c1"): Self.badGateway]
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "b", isVisible: true))

        try await settle { context.provider.eventsRequests.count == 3 }
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        #expect(context.provider.eventsRequests.count == 3)
        #expect(context.provider.eventsRequests.last?.cursor == "c1")
        #expect(Self.cardIDs(context.sut) == ["a", "b"])
    }

    @Test("A next page that failed is asked again with the same cursor")
    func failedNextPageKeepsItsCursor() async throws {
        let context = try await Self.makePollingContext(pages: [
            .init(category: 1, cursor: nil): Self.page(["a"], cursor: "c1"),
            .init(category: 1, cursor: "c1"): Self.page(["b"]),
        ])

        context.provider.eventErrors = [.init(category: 1, cursor: "c1"): Self.badGateway]
        context.sut.handleViewAction(.loadNextPage)
        try await settle(timeout: .seconds(5)) { context.sut.loadingState == .paginationError }

        context.provider.eventErrors = [:]
        context.sut.handleViewAction(.retryNextPage)

        try await settle { Self.cardIDs(context.sut) == ["a", "b"] }
        #expect(context.provider.eventsRequests.map(\.cursor) == [nil, "c1", "c1", "c1"])
    }

    @Test("A failed first page keeps the feed as it is")
    func failedFirstPageIsNotAStaleCursor() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.provider.eventErrors = [.init(category: 1, cursor: nil): Self.badGateway]
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))

        try await settle { context.provider.eventsRequests.count == 2 }
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        #expect(context.provider.eventsRequests.count == 2)
        #expect(Self.cardIDs(context.sut) == ["a"])
    }

    @Test("Three failed refreshes in a row report outdated data once, and again only after the cooldown")
    func repeatedFailuresReportOutdatedData() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.provider.eventErrors = [.init(category: 1, cursor: nil): Self.unavailable]

        try await Self.failRefresh(context, expectingRequests: 2)
        try await Self.failRefresh(context, expectingRequests: 3)
        try await Self.failRefresh(context, expectingRequests: 4)
        try await settle { context.outdatedDataLog.reports == 1 }

        try await Self.failRefresh(context, expectingRequests: 5)
        try await Self.failRefresh(context, expectingRequests: 6)
        #expect(context.outdatedDataLog.reports == 1)

        context.clock.advance(by: 300)
        try await Self.failRefresh(context, expectingRequests: 7)
        try await settle { context.outdatedDataLog.reports == 2 }
    }

    @Test("In background a page coming on screen is not asked for")
    func backgroundPausesRefreshes() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        #expect(context.provider.eventsRequests.count == 1)

        context.notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        try await settle { context.provider.eventsRequests.count == 2 }
    }

    @Test("A poll answer arriving after the tab changed is not merged into the new tab")
    func pollAnswerAfterTabChangeIsDropped() async throws {
        let context = try await Self.makePollingContext(
            categories: [1, 2],
            pages: [
                .init(category: 1, cursor: nil): Self.page(["a"]),
                .init(category: 2, cursor: nil): Self.page(["b"]),
            ]
        )

        context.provider.slowEventCategories = [1]
        context.provider.eventPages[.init(category: 1, cursor: nil)] = PolymarketEventsPage(
            events: [Self.event(id: "b", title: "stale"), Self.event(id: "a")],
            cursor: nil,
            hasNext: false
        )
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        context.notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        try await settle { context.provider.eventsRequests.count == 2 }

        context.sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 2, title: "")
        try await settle { Self.cardIDs(context.sut) == ["b"] }
        try await Task.sleep(nanoseconds: PolymarketAPIProviderStub.slowEventsDelay * 2)

        #expect(context.sut.eventCards.first?.title == "b")
    }
}

// MARK: - Helpers

private extension PolymarketEventsBlockViewModelTests {
    static func makeSUT(
        provider: PolymarketAPIProviderStub,
        routable: PolymarketEventOpeningRoutableSpy = PolymarketEventOpeningRoutableSpy.ignored,
        isRegionRestricted: Bool = false,
        notificationCenter: NotificationCenter = NotificationCenter(),
        clock: PollingClock = PollingClock(),
        outdatedDataLog: OutdatedDataLog = OutdatedDataLog()
    ) -> PolymarketEventsBlockViewModel {
        let refreshCenter = PolymarketMainRefreshCenter()

        return PolymarketEventsBlockViewModel(
            apiProvider: provider,
            refreshCenter: refreshCenter,
            activityHandler: PolymarketMainActivityHandler(
                fundsArrivalTracker: PolymarketFundsArrivalTracker(balancePublisher: Empty().eraseToAnyPublisher()),
                refreshCenter: refreshCenter
            ),
            isRegionRestricted: { isRegionRestricted },
            routable: routable,
            notificationCenter: notificationCenter,
            now: { clock.now },
            reportOutdatedData: { outdatedDataLog.reports += 1 }
        )
    }

    struct PollingContext {
        let sut: PolymarketEventsBlockViewModel
        let provider: PolymarketAPIProviderStub
        let clock: PollingClock
        let outdatedDataLog: OutdatedDataLog
        let notificationCenter: NotificationCenter
    }

    static let visibilitySettle: UInt64 = 800_000_000
    static let badGateway = PolymarketAPIError.http(statusCode: 502, problemDetail: nil)
    static let unavailable = PolymarketAPIError.http(statusCode: 503, problemDetail: nil)

    static func makePollingContext(
        categories: [Int] = [1],
        pages: [PolymarketAPIProviderStub.EventsPageKey: PolymarketEventsPage]
    ) async throws -> PollingContext {
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = categories.map(category)
        provider.eventPages = pages
        let clock = PollingClock()
        let outdatedDataLog = OutdatedDataLog()
        let notificationCenter = NotificationCenter()
        let sut = makeSUT(provider: provider, notificationCenter: notificationCenter, clock: clock, outdatedDataLog: outdatedDataLog)

        try await settle { !sut.eventCards.isEmpty }

        return PollingContext(
            sut: sut,
            provider: provider,
            clock: clock,
            outdatedDataLog: outdatedDataLog,
            notificationCenter: notificationCenter
        )
    }

    static func failRefresh(_ context: PollingContext, expectingRequests count: Int) async throws {
        context.clock.advance(by: 21)

        try await settle {
            context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
            return context.provider.eventsRequests.count == count
        }
    }

    static func cardIDs(_ sut: PolymarketEventsBlockViewModel) -> [String] {
        sut.eventCards.map(\.id)
    }

    static func market(id: String, outcomes: [PolymarketOutcome]) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            conditionId: nil,
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
            orderIndex: 0,
            outcomes: outcomes
        )
    }

    static func category(_ id: Int) -> PolymarketCategory {
        PolymarketCategory(id: id, label: "\(id)", icon: nil)
    }

    static func page(_ ids: [String], cursor: String? = nil, outcomes: [PolymarketOutcome] = []) -> PolymarketEventsPage {
        PolymarketEventsPage(
            events: ids.map { event(id: $0, outcomes: outcomes) },
            cursor: cursor,
            hasNext: cursor != nil
        )
    }

    static func event(id: String, title: String? = nil, outcomes: [PolymarketOutcome] = []) -> PolymarketEvent {
        let markets = outcomes.isEmpty ? [] : [market(id: "\(id)-market", outcomes: outcomes)]

        return PolymarketEvent(
            id: id,
            slug: id,
            title: title ?? id,
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

// MARK: - Doubles

private final class PollingClock {
    private(set) var now = Date(timeIntervalSince1970: 1_800_000_000)

    func advance(by interval: TimeInterval) {
        now = now.addingTimeInterval(interval)
    }
}

private final class OutdatedDataLog {
    var reports = 0
}

private enum EventsTestError: Error {
    case unavailable
}
