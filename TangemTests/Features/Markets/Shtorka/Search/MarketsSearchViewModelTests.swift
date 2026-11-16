//
//  MarketsSearchViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Testing
import TangemTestKit
@testable import Tangem

@MainActor
@Suite("Markets search view model")
struct MarketsSearchViewModelTests {
    @Test("Typing is debounced into one search for the last entered text")
    func typingIsDebounced() async {
        await withInjectedTangemApiService(FakeTangemApiService()) {
            let sut = makeSUT()

            sut.header.enteredSearchText = "s"
            sut.header.enteredSearchText = "so"
            sut.header.enteredSearchText = "sol"
            sut.scheduler.advance(by: .seconds(1))

            #expect(sut.fetches.count == 1)
            #expect(sut.dataProvider.lastSearchTextValue == "sol")
        }
    }

    @Test("Clear and cancel reset the search once", arguments: [SearchAction.clear, .cancel])
    func resetFetchesOnce(action: SearchAction) async {
        await withInjectedTangemApiService(FakeTangemApiService()) {
            let sut = makeSUT()

            sut.header.enteredSearchText = "sol"
            sut.scheduler.advance(by: .seconds(1))
            sut.header.enteredSearchText = ""
            action.perform(on: sut.header)
            sut.scheduler.advance(by: .seconds(1))

            #expect(sut.fetches.count == 2)
            #expect(sut.dataProvider.lastSearchTextValue == "")
        }
    }

    @Test("Cancelling again after refocusing leaves the search mode")
    func secondCancelLeavesSearchMode() async {
        await withInjectedTangemApiService(FakeTangemApiService()) {
            let sut = makeSUT()

            sut.header.inputShouldBecomeFocused = true
            sut.header.cancelSearchBarAction()
            sut.scheduler.advance(by: .seconds(1))
            sut.header.inputShouldBecomeFocused = true
            sut.header.cancelSearchBarAction()

            #expect(sut.viewModel.isSearching == false)
        }
    }

    @Test("Typing after clear or cancel starts a new search", arguments: [SearchAction.clear, .cancel])
    func typingAfterResetSearches(action: SearchAction) async {
        await withInjectedTangemApiService(FakeTangemApiService()) {
            let sut = makeSUT()

            sut.header.enteredSearchText = "sol"
            sut.scheduler.advance(by: .seconds(1))
            sut.header.enteredSearchText = ""
            action.perform(on: sut.header)
            sut.scheduler.advance(by: .seconds(1))
            sut.header.enteredSearchText = "eth"
            sut.scheduler.advance(by: .seconds(1))

            #expect(sut.fetches.count == 3)
            #expect(sut.dataProvider.lastSearchTextValue == "eth")
        }
    }
}

// MARK: - Helpers

extension MarketsSearchViewModelTests {
    enum SearchAction: CaseIterable, CustomTestStringConvertible {
        case clear
        case cancel

        var testDescription: String {
            switch self {
            case .clear: "clear"
            case .cancel: "cancel"
            }
        }

        func perform(on header: MarketsSearchHeaderViewModel) {
            switch self {
            case .clear: header.clearSearchBarAction()
            case .cancel: header.cancelSearchBarAction()
            }
        }
    }
}

private extension MarketsSearchViewModelTests {
    struct SUT {
        let viewModel: MarketsSearchViewModel
        let dataProvider: MarketsListDataProvider
        let scheduler: ManualSchedulerStub
        let fetchSpy: FetchSpy
        let coordinator: MarketsRoutableStub

        var header: MarketsSearchHeaderViewModel { viewModel.headerViewModel }
        var fetches: [MarketsListDataProvider.Event] { fetchSpy.events }
    }

    final class FetchSpy {
        private(set) var events: [MarketsListDataProvider.Event] = []
        private var subscription: AnyCancellable?

        init(dataProvider: MarketsListDataProvider) {
            subscription = dataProvider.$lastEvent
                .dropFirst()
                .filter { $0 == .loading }
                .sink { [weak self] in self?.events.append($0) }
        }
    }

    final class MarketsRoutableStub: MarketsRoutable {
        func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel) {}
    }

    struct MarketsQuotesUpdateHelperStub: MarketsQuotesUpdateHelper {
        func updateQuotes(marketsTokens: [MarketsTokenModel], for baseCurrencyCode: String) {}
        func updateQuote(marketToken: MarketsTokenDetailsModel, for baseCurrencyCode: String) {}
    }

    func makeSUT() -> SUT {
        let dataProvider = MarketsListDataProvider()
        let scheduler = ManualSchedulerStub()
        let coordinator = MarketsRoutableStub()
        let viewModel = MarketsSearchViewModel(
            initialOrderType: nil,
            initialIntervalType: nil,
            quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelperStub(),
            coordinator: coordinator,
            dataProvider: dataProvider,
            searchInputScheduler: scheduler
        )
        let fetchSpy = FetchSpy(dataProvider: dataProvider)

        return SUT(viewModel: viewModel, dataProvider: dataProvider, scheduler: scheduler, fetchSpy: fetchSpy, coordinator: coordinator)
    }
}
