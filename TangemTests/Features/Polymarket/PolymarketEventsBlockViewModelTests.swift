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
}

// MARK: - Helpers

private extension PolymarketEventsBlockViewModelTests {
    static func makeSUT(
        provider: PolymarketAPIProviderStub,
        routable: PolymarketEventOpeningRoutableSpy = PolymarketEventOpeningRoutableSpy.ignored,
        isRegionRestricted: Bool = false
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
            notificationCenter: NotificationCenter()
        )
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
        PolymarketCategory(id: id, label: "\(id)", iconURL: nil)
    }

    static func page(_ ids: [String], cursor: String? = nil, outcomes: [PolymarketOutcome] = []) -> PolymarketEventsPage {
        PolymarketEventsPage(
            events: ids.map { event(id: $0, outcomes: outcomes) },
            cursor: cursor,
            hasNext: cursor != nil
        )
    }

    static func event(id: String, outcomes: [PolymarketOutcome]) -> PolymarketEvent {
        let markets = outcomes.isEmpty ? [] : [market(id: "\(id)-market", outcomes: outcomes)]

        return PolymarketEvent(
            id: id,
            slug: id,
            title: id,
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

private enum EventsTestError: Error {
    case unavailable
}
