//
//  PolymarketSearchViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket search")
@MainActor
struct PolymarketSearchViewModelTests {
    @Test("A query shorter than three characters never reaches the backend")
    func shortQueryIsNotSearched() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [], hasNext: false))])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "uz"
        try await Self.drain()

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

        sut.loadMore()
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

        sut.loadMore()
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        #expect(sut.eventCards.map(\.id) == ["a", "b", "c"])
    }

    @Test("A page that will never come is not asked for again")
    func theLastPageIsNotRequestedAgain() async throws {
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [Self.event(id: "a")], hasNext: false))])
        let sut = Self.makeSUT(provider: provider)

        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        sut.loadMore()

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

        sut.retry()
        try await Self.settle(sut) { $0.state == .loaded }

        sut.loadMore()
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
        let coordinator = PolymarketSearchRoutableSpy()
        let sut = Self.makeSUT(provider: provider, coordinator: coordinator)

        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        sut.openEventDetails(eventID: "a")

        #expect(coordinator.openedEventIDs == ["a"])
    }

    @Test("Choosing an outcome on a result opens the order, not the event")
    func choosingOutcomeOpensOrder() async throws {
        let outcome = PolymarketOutcome(assetId: "yes", title: "Yes", probability: 0.42)
        let market = Self.market(id: "m1", outcomes: [outcome])
        let event = Self.event(id: "a", markets: [market])
        let provider = PolymarketAPIProviderStub(searchResults: [.success(Self.page(events: [event], hasNext: false))])
        let coordinator = PolymarketSearchRoutableSpy()
        let sut = Self.makeSUT(provider: provider, coordinator: coordinator)

        sut.query = "uzbekistan"
        try await Self.settle(sut) { $0.state == .allDataLoaded }

        let selected = try #require(sut.eventCards.first?.rows.first?.outcomes.first)
        selected.onSelect()

        #expect(coordinator.openedEventIDs.isEmpty)
        #expect(coordinator.openedOutcomes.map(\.market.id) == ["m1"])
        #expect(coordinator.openedOutcomes.map(\.outcome.assetId) == ["yes"])
        #expect(coordinator.openedOutcomes.map(\.eventTitle) == ["a"])
    }
}

// MARK: - Fixtures

private extension PolymarketSearchViewModelTests {
    static func makeSUT(
        provider: PolymarketAPIProvider,
        coordinator: PolymarketSearchRoutableSpy? = nil
    ) -> PolymarketSearchViewModel {
        let viewModel = PolymarketSearchViewModel(apiProvider: provider, debounceInterval: .zero)
        viewModel.coordinator = coordinator

        return viewModel
    }

    static func settle(
        _ sut: PolymarketSearchViewModel,
        until isSatisfied: (PolymarketSearchViewModel) -> Bool
    ) async throws {
        for _ in 0 ..< Constants.settleAttempts {
            if isSatisfied(sut) { return }

            try await Task.sleep(nanoseconds: Constants.settleInterval)
        }

        Issue.record("The search never settled, last state \(sut.state)")
    }

    static func drain() async throws {
        for _ in 0 ..< Constants.drainAttempts {
            try await Task.sleep(nanoseconds: Constants.settleInterval)
        }
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
        static let drainAttempts = 20
        static let settleInterval: UInt64 = 5_000_000
    }
}
