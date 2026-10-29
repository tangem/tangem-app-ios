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
import TangemPolymarketUI
@testable import Tangem

@Suite("Polymarket search", .timeLimit(.minutes(1)))
@MainActor
struct PolymarketSearchBlockViewModelTests {
    @Test("A query shortened below three characters drops the results and never reaches the backend")
    func shortQueryIsNotSearched() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [Self.event(id: "a")], hasNext: false))])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "uzbekistan"
        await Self.state(of: sut, becomes: .allDataLoaded)

        sut.query = "uz"
        await Self.state(of: sut, becomes: .prompt)
        #expect(sut.eventCards.isEmpty)

        sut.query = "uzbek"
        await Self.state(of: sut, becomes: .noResults)

        #expect(provider.searchRequests.map(\.query) == ["uzbekistan", "uzbek"])
    }

    @Test("The first page is asked for by number, starting at one")
    func theFirstPageIsRequestedByNumber() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [Self.event(id: "a")], hasNext: false))])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "  uzbekistan  "
        await Self.state(of: sut, becomes: .allDataLoaded)

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
        await Self.state(of: sut, becomes: .loaded)

        sut.query = "second"
        await Self.state(of: sut, becomes: .allDataLoaded)

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
        await Self.state(of: sut, becomes: .loaded)

        sut.handleViewAction(.loadNextPage)
        await Self.state(of: sut, becomes: .allDataLoaded)

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
        await Self.state(of: sut, becomes: .loaded)

        sut.handleViewAction(.loadNextPage)
        await Self.state(of: sut, becomes: .allDataLoaded)

        #expect(sut.eventCards.map(\.id) == ["a", "b", "c"])
    }

    @Test("A page that will never come is not asked for again")
    func theLastPageIsNotRequestedAgain() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [Self.event(id: "a")], hasNext: false))])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "uzbekistan"
        await Self.state(of: sut, becomes: .allDataLoaded)

        sut.handleViewAction(.loadNextPage)

        #expect(sut.state == .allDataLoaded)
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
        await Self.state(of: sut, becomes: .error)

        sut.handleViewAction(.retry)
        await Self.state(of: sut, becomes: .loaded)

        sut.handleViewAction(.loadNextPage)
        await Self.state(of: sut, becomes: .paginationError)

        #expect(sut.eventCards.map(\.id) == ["a"])
    }

    @Test("Choosing a result opens the event details")
    func choosingResultOpensEventDetails() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [Self.event(id: "a")], hasNext: false))])
        let routable = PolymarketEventOpeningRoutableSpy()
        let sut = Self.makeSUT(provider: provider, routable: routable)

        sut.isFieldActive = true
        sut.query = "uzbekistan"
        await Self.state(of: sut, becomes: .allDataLoaded)

        sut.handleViewAction(.openEventDetails(id: "a"))

        #expect(routable.openedEventIDs == ["a"])
        #expect(routable.openedEventTitles == ["a"])
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
        await Self.state(of: sut, becomes: .allDataLoaded)

        let selected = try #require(sut.eventCards.first?.regularModel?.rows.first?.outcomes.first)
        selected.onSelect()

        #expect(!sut.isFieldActive)
        #expect(sut.isSearching)
        #expect(routable.openedEventIDs.isEmpty)
        #expect(routable.openedOutcomes.map(\.market.id) == ["m1"])
        #expect(routable.openedOutcomes.map(\.outcome.assetId) == ["yes"])
        #expect(routable.openedOutcomes.map(\.eventTitle) == ["a"])
        #expect(routable.openedOutcomes.map(\.isBuy) == [true])
    }

    @Test("A periodic refresh updates the results on screen in place, and an outcome chosen on a card drawn before it opens the refreshed market")
    func periodicRefreshUpdatesTheVisibleResults() async throws {
        let staleOutcome = Self.outcome(probability: "0.42")
        let freshOutcome = Self.outcome(probability: "0.55")
        let provider = PolymarketAPIProviderStub(searchResults: [
            .success(Self.page(events: [Self.event(id: "a", markets: [Self.market(id: "m1", outcomes: [staleOutcome])])], hasNext: false)),
            .success(Self.page(
                events: [Self.event(id: "a", markets: [Self.market(id: "m1", outcomes: [freshOutcome])]), Self.event(id: "b")],
                hasNext: false
            )),
        ])
        let routable = PolymarketEventOpeningRoutableSpy()
        let delays = PolymarketSteppedDelayProvider()
        let sut = Self.makeSUT(provider: provider, routable: routable, delays: delays)

        sut.query = "uzbekistan"
        await Self.state(of: sut, becomes: .allDataLoaded)
        let resultBeforeRefresh = try #require(sut.eventCards.first?.regularModel?.rows.first?.outcomes.first)

        try await delays.waitUntilParked(Self.refreshInterval)
        delays.resume(Self.refreshInterval)
        await Self.firstPriceText(of: sut, becomes: PolymarketPriceFormatter.centsText(Decimal(string: "0.55")))

        #expect(sut.eventCards.map(\.id) == ["a"])
        #expect(sut.state == .allDataLoaded)
        #expect(provider.searchRequests.map(\.query) == ["uzbekistan", "uzbekistan"])
        #expect(provider.searchRequests.map(\.page) == [1, 1])

        resultBeforeRefresh.onSelect()

        #expect(routable.openedOutcomes.map(\.outcome.probability) == [Decimal(string: "0.55")])
        #expect(routable.openedOutcomes.map(\.market.id) == ["m1"])
    }

    @Test("The background stops the periodic refresh, and coming back refreshes the results on screen at once")
    func comingBackRefreshesTheVisibleResults() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [
            .success(Self.page(events: [Self.event(id: "a", markets: [Self.market(id: "m1", outcomes: [Self.outcome(probability: "0.42")])])], hasNext: false)),
            .success(Self.page(events: [Self.event(id: "a", markets: [Self.market(id: "m1", outcomes: [Self.outcome(probability: "0.55")])])], hasNext: false)),
        ])
        let appState = AppStateObserverStub()
        let delays = PolymarketSteppedDelayProvider()
        let sut = Self.makeSUT(provider: provider, appState: appState, delays: delays)

        sut.query = "uzbekistan"
        await Self.state(of: sut, becomes: .allDataLoaded)
        try await delays.waitUntilParked(Self.refreshInterval)

        appState.enterBackground()
        try await delays.cancellations.next()
        #expect(delays.parkedWaits.isEmpty)

        appState.enterForeground()
        await Self.firstPriceText(of: sut, becomes: PolymarketPriceFormatter.centsText(Decimal(string: "0.55")))
        try await delays.waitUntilParked(Self.refreshInterval)

        #expect(provider.searchRequests.map(\.page) == [1, 1])
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
        await Self.state(of: sut, becomes: .allDataLoaded)

        let selected = try #require(sut.eventCards.first?.regularModel?.rows.first?.outcomes.first)
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
        await Self.state(of: sut, becomes: .allDataLoaded)

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
        await Self.state(of: sut, becomes: .allDataLoaded)

        let selected = try #require(sut.eventCards.first?.regularModel?.rows.first?.outcomes.first)
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
        await Self.state(of: sut, becomes: .allDataLoaded)

        #expect(sut.isSearching)

        sut.handleViewAction(.cancel)

        #expect(!sut.isSearching)
        #expect(!sut.isFieldActive)
        #expect(sut.query.isEmpty)
        #expect(sut.eventCards.isEmpty)
        #expect(sut.state == .prompt)
    }

    @Test("With phase two a live match found by search gets the live card, from REST")
    func liveMatchInSearchGetsTheLiveCard() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [PolymarketLiveGamesFixtures.basketball()], hasNext: false))])
        let sut = Self.makeSUT(provider: provider, usesPhaseTwoCards: true)

        sut.query = "cavaliers"
        await Self.state(of: sut, becomes: .allDataLoaded)

        #expect(sut.eventCards.first?.liveGameModel?.score == PolymarketLiveGameCard.Score(home: "101", away: "98"))
    }
}

// MARK: - Fixtures

private extension PolymarketSearchBlockViewModelTests {
    static let refreshInterval: TimeInterval = 20

    static func makeSUT(
        provider: PolymarketAPIProvider,
        routable: PolymarketEventOpeningRoutableSpy = PolymarketEventOpeningRoutableSpy.ignored,
        isRegionRestricted: Bool = false,
        fundsArrivalTracker: PolymarketFundsArrivalTracker = PolymarketFundsArrivalTracker(balancePublisher: Empty().eraseToAnyPublisher()),
        usesPhaseTwoCards: Bool = false,
        appState: AppStateObserverStub = AppStateObserverStub(),
        delays: PolymarketSteppedDelayProvider = PolymarketSteppedDelayProvider()
    ) -> PolymarketSearchBlockViewModel {
        PolymarketSearchBlockViewModel(
            apiProvider: provider,
            activityHandler: PolymarketMainActivityHandler(
                fundsArrivalTracker: fundsArrivalTracker,
                refreshCenter: PolymarketMainRefreshCenter()
            ),
            isRegionRestricted: { isRegionRestricted },
            usesPhaseTwoCards: usesPhaseTwoCards,
            routable: routable,
            debounceInterval: .zero,
            appStateObserver: appState,
            delayProvider: delays
        )
    }

    static func state(of sut: PolymarketSearchBlockViewModel, becomes state: PolymarketSearchBlockViewModel.State) async {
        _ = await sut.$state.firstValue { $0 == state }
    }

    static func firstPriceText(of sut: PolymarketSearchBlockViewModel, becomes text: String) async {
        _ = await sut.$eventCards.firstValue { $0.first?.regularModel?.rows.first?.outcomes.first?.priceText == text }
    }

    static func outcome(probability: String) -> PolymarketOutcome {
        PolymarketOutcome(assetId: "yes", title: "Yes", probability: Decimal(string: probability))
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
}
