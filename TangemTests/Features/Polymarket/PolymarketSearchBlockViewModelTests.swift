//
//  PolymarketSearchBlockViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket search")
@MainActor
struct PolymarketSearchBlockViewModelTests {
    @Test("A query shorter than three characters never reaches the backend")
    func shortQueryIsNotSearched() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [], hasNext: false))])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "uz"
        try await drain()

        #expect(provider.searchRequests.isEmpty)

        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .noResults }

        #expect(provider.searchRequests.map(\.query) == ["uzbekistan"])
    }

    @Test("A query with no matches shows the empty result, not an error")
    func emptyResultIsNotAnError() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [], hasNext: false))])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "saburo"
        try await Self.settle(sut) { $0.state == .noResults }

        #expect(sut.eventCards.isEmpty)
    }

    @Test("The first page is asked for by number, starting at one")
    func theFirstPageIsRequestedByNumber() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [Self.event(id: "a")], hasNext: false))])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "  uzbekistan  "
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        let request = try #require(provider.searchRequests.first)

        #expect(request.query == "uzbekistan")
        #expect(request.page == 1)
        #expect(sut.eventCards.map(\.id) == ["a"])
    }

    @Test("Typing again restarts the search from the first page instead of appending")
    func aNewQueryStartsOver() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [
            .success(Self.page(events: [Self.event(id: "a")], hasNext: true)),
            .success(Self.page(events: [Self.event(id: "b")], hasNext: false)),
        ])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "first"
        try await Self.settle(sut) { $0.state == .loaded }

        sut.query = "second"
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        #expect(provider.searchRequests.map(\.page) == [1, 1])
        #expect(sut.eventCards.map(\.id) == ["b"])
    }

    @Test("The next page is appended to what is already on screen")
    func theNextPageIsAppended() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [
            .success(Self.page(events: [Self.event(id: "a")], hasNext: true)),
            .success(Self.page(events: [Self.event(id: "b")], hasNext: false)),
        ])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .loaded }

        sut.handleViewAction(.loadNextPage)
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        #expect(provider.searchRequests.map(\.page) == [1, 2])
        #expect(sut.eventCards.map(\.id) == ["a", "b"])
    }

    @Test("A page that repeats what is already on screen adds only what is new")
    func repeatedEventsAreNotDuplicated() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [
            .success(Self.page(events: [Self.event(id: "a"), Self.event(id: "b")], hasNext: true)),
            .success(Self.page(events: [Self.event(id: "b"), Self.event(id: "c")], hasNext: false)),
        ])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .loaded }

        sut.handleViewAction(.loadNextPage)
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        #expect(sut.eventCards.map(\.id) == ["a", "b", "c"])
    }

    @Test("A page that will never come is not asked for again")
    func theLastPageIsNotRequestedAgain() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [Self.event(id: "a")], hasNext: false))])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        sut.handleViewAction(.loadNextPage)

        #expect(provider.searchRequests.count == 1)
    }

    @Test("A failure with nothing on screen takes the whole screen, a failed page only the footer")
    func failuresAreSplitByWhatIsOnScreen() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [
            .failure(PolymarketDepositWalletServiceStub.StubError()),
            .success(Self.page(events: [Self.event(id: "a")], hasNext: true)),
            .failure(PolymarketDepositWalletServiceStub.StubError()),
        ])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .error }

        sut.handleViewAction(.retry)
        try await Self.settle(sut) { $0.state == .loaded }

        sut.handleViewAction(.loadNextPage)
        try await Self.settle(sut) { $0.state == .paginationError }

        #expect(sut.eventCards.map(\.id) == ["a"])
    }

    @Test("Erasing the query drops the results and goes back to the prompt")
    func clearingGoesBackToThePrompt() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [Self.event(id: "a")], hasNext: false))])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        sut.query = ""
        try await Self.settle(sut) { $0.state == .prompt }

        #expect(sut.eventCards.isEmpty)
        #expect(provider.searchRequests.count == 1)
    }

    @Test("Choosing a result opens the event details")
    func choosingResultOpensEventDetails() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [Self.event(id: "a")], hasNext: false))])
        let routable = PolymarketEventOpeningRoutableSpy()
        let sut = Self.makeSUT(provider: provider, routable: routable)

        sut.isFieldActive = true
        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        sut.handleViewAction(.openEventDetails(id: "a"))

        #expect(routable.openedEventIDs == ["a"])
        #expect(routable.openedEventCategories == [nil])
        #expect(!sut.isFieldActive)
        #expect(sut.isSearching)
    }

    @Test("Choosing an outcome on a result opens the order, not the event")
    func choosingOutcomeOpensOrder() async throws {
        let outcome = PolymarketOutcome(assetId: "yes", title: "Yes", probability: 0.42)
        let market = Self.market(id: "m1", outcomes: [outcome])
        let event = Self.event(id: "a", markets: [market])
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [event], hasNext: false))])
        let routable = PolymarketEventOpeningRoutableSpy()
        let sut = Self.makeSUT(provider: provider, routable: routable)

        sut.isFieldActive = true
        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        let selected = try #require(sut.eventCards.first?.rows.first?.outcomes.first)
        selected.onSelect()

        #expect(!sut.isFieldActive)
        #expect(sut.isSearching)
        #expect(routable.openedEventIDs.isEmpty)
        #expect(routable.openedOutcomes.map(\.market.id) == ["m1"])
        #expect(routable.openedOutcomes.map(\.outcome.assetId) == ["yes"])
        #expect(routable.openedOutcomes.map(\.eventTitle) == ["a"])
        #expect(routable.openedOutcomes.map(\.isBuy) == [true])
    }

    @Test("An outcome chosen on a result drawn before the results refreshed opens the order with the refreshed market")
    func outcomeChosenAfterRefreshOpensTheFreshMarket() async throws {
        let staleOutcome = PolymarketOutcome(assetId: "yes", title: "Yes", probability: Decimal(string: "0.42"))
        let freshOutcome = PolymarketOutcome(assetId: "yes", title: "Yes", probability: Decimal(string: "0.55"))
        let provider = PolymarketAPIProviderStub(searchResults: [
            .success(Self.page(events: [Self.event(id: "a", markets: [Self.market(id: "m1", outcomes: [staleOutcome])])], hasNext: false)),
            .success(Self.page(events: [Self.event(id: "a", markets: [Self.market(id: "m1", outcomes: [freshOutcome])])], hasNext: false)),
        ])
        let routable = PolymarketEventOpeningRoutableSpy()
        let sut = Self.makeSUT(provider: provider, routable: routable)

        sut.query = "first"
        try await Self.settle(sut) { $0.state == .allDataLoaded }
        let resultBeforeRefresh = try #require(sut.eventCards.first?.rows.first?.outcomes.first)

        sut.query = "second"
        try await Self.settle(sut) { $0.eventCards.first?.rows.first?.outcomes.first?.priceText == PolymarketPriceFormatter.centsText(Decimal(string: "0.55")) }

        resultBeforeRefresh.onSelect()

        #expect(routable.openedOutcomes.map(\.outcome.probability) == [Decimal(string: "0.55")])
        #expect(routable.openedOutcomes.map(\.market.id) == ["m1"])
    }

    @Test("An order placed from search expects a balance change")
    func orderFromSearchExpectsBalanceChange() async throws {
        let outcome = PolymarketOutcome(assetId: "yes", title: "Yes", probability: 0.42)
        let event = Self.event(id: "a", markets: [Self.market(id: "m1", outcomes: [outcome])])
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [event], hasNext: false))])
        let routable = PolymarketEventOpeningRoutableSpy()
        let tracker = PolymarketFundsArrivalTracker(balancePublisher: Empty().eraseToAnyPublisher())
        let sut = Self.makeSUT(provider: provider, routable: routable, fundsArrivalTracker: tracker)

        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        let selected = try #require(sut.eventCards.first?.rows.first?.outcomes.first)
        selected.onSelect()
        routable.lastOnPlaced?(Task { nil })

        #expect(tracker.isBalanceChangeExpected)
        withExtendedLifetime(sut) {}
    }

    @Test("An order placed from event details opened in search expects a balance change")
    func orderFromSearchedEventExpectsBalanceChange() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [Self.event(id: "a")], hasNext: false))])
        let routable = PolymarketEventOpeningRoutableSpy()
        let tracker = PolymarketFundsArrivalTracker(balancePublisher: Empty().eraseToAnyPublisher())
        let sut = Self.makeSUT(provider: provider, routable: routable, fundsArrivalTracker: tracker)

        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        sut.handleViewAction(.openEventDetails(id: "a"))
        routable.lastOnPlaced?(Task { nil })

        #expect(tracker.isBalanceChangeExpected)
        withExtendedLifetime(sut) {}
    }

    @Test("Choosing an outcome in a restricted region opens the region warning instead of the order")
    func choosingOutcomeInRestrictedRegionOpensWarning() async throws {
        let outcome = PolymarketOutcome(assetId: "yes", title: "Yes", probability: 0.42)
        let event = Self.event(id: "a", markets: [Self.market(id: "m1", outcomes: [outcome])])
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [event], hasNext: false))])
        let routable = PolymarketEventOpeningRoutableSpy()
        let sut = Self.makeSUT(provider: provider, routable: routable, isRegionRestricted: true)

        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        let selected = try #require(sut.eventCards.first?.rows.first?.outcomes.first)
        selected.onSelect()

        #expect(routable.openedOutcomes.isEmpty)
        #expect(routable.regionWarningOpenings == 1)
        withExtendedLifetime(sut) {}
    }

    @Test("Cancelling leaves the search and drops the query and the results")
    func cancellingLeavesTheSearch() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [Self.event(id: "a")], hasNext: false))])
        let sut = Self.makeSUT(provider: provider)

        sut.isFieldActive = true
        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        #expect(sut.isSearching)

        sut.handleViewAction(.cancel)

        #expect(!sut.isSearching)
        #expect(!sut.isFieldActive)
        #expect(sut.query.isEmpty)
        #expect(sut.eventCards.isEmpty)
        #expect(sut.state == .prompt)
    }
}

// MARK: - Fixtures

private extension PolymarketSearchBlockViewModelTests {
    static func makeSUT(
        provider: PolymarketAPIProvider,
        routable: PolymarketEventOpeningRoutableSpy = PolymarketEventOpeningRoutableSpy.ignored,
        isRegionRestricted: Bool = false,
        fundsArrivalTracker: PolymarketFundsArrivalTracker = PolymarketFundsArrivalTracker(balancePublisher: Empty().eraseToAnyPublisher())
    ) -> PolymarketSearchBlockViewModel {
        PolymarketSearchBlockViewModel(
            apiProvider: provider,
            activityHandler: PolymarketMainActivityHandler(
                fundsArrivalTracker: fundsArrivalTracker,
                refreshCenter: PolymarketMainRefreshCenter()
            ),
            isRegionRestricted: { isRegionRestricted },
            routable: routable,
            debounceInterval: .zero
        )
    }

    static func settle(
        _ sut: PolymarketSearchBlockViewModel,
        until isSatisfied: (PolymarketSearchBlockViewModel) -> Bool
    ) async throws {
        for _ in 0 ..< Constants.settleAttempts {
            if isSatisfied(sut) { return }

            try await Task.sleep(nanoseconds: Constants.settleInterval)
        }

        Issue.record("The search never settled, last state \(sut.state)")
    }

    static func page(events: [PolymarketEvent], hasNext: Bool) -> PolymarketSearchResult {
        PolymarketSearchResult(events: events, page: nil, total: events.count, hasNext: hasNext)
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

    static func event(id: String, markets: [PolymarketMarket] = []) -> PolymarketEvent {
        PolymarketEvent(
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

    enum Constants {
        static let settleAttempts = 200
        static let settleInterval: UInt64 = 5_000_000
    }
}
