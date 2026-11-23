//
//  MarketsSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import struct TangemUIUtils.AlertBinder

final class MarketsSearchViewModel: ObservableObject {
    private typealias SearchInput = MarketsSearchHeaderViewModel.SearchInput

    // MARK: - Published Properties

    @Published private(set) var headerViewModel: MarketsSearchHeaderViewModel
    @Published private(set) var marketsRatingHeaderViewModel: MarketsRatingHeaderViewModel
    @Published private(set) var tokenListViewModel: MarketsTokenListViewModel
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var isSearchFieldFocused: Bool = false

    // MARK: - Private Properties

    private weak var coordinator: MarketsRoutable?

    private let filterProvider: MarketsListDataFilterProvider
    private let dataProvider: MarketsListDataProvider
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
    private let quotesUpdatesScheduler = MarketsQuotesUpdatesScheduler()

    private var marketCapFormatter: MarketCapFormatter
    private var bag = Set<AnyCancellable>()

    private var currentSearchValue: String = ""

    // MARK: - Init

    convenience init(
        initialOrderType: MarketsListOrderType?,
        initialIntervalType: MarketsPriceIntervalType?,
        quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper,
        coordinator: MarketsRoutable
    ) {
        self.init(
            initialOrderType: initialOrderType,
            initialIntervalType: initialIntervalType,
            quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper,
            coordinator: coordinator,
            dataProvider: MarketsListDataProvider(),
            searchInputScheduler: DispatchQueue.main
        )
    }

    init(
        initialOrderType: MarketsListOrderType?,
        initialIntervalType: MarketsPriceIntervalType?,
        quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper,
        coordinator: MarketsRoutable,
        dataProvider: MarketsListDataProvider,
        searchInputScheduler: some Scheduler
    ) {
        self.quotesRepositoryUpdateHelper = quotesRepositoryUpdateHelper
        self.dataProvider = dataProvider
        self.coordinator = coordinator

        filterProvider = MarketsListDataFilterProvider(
            initialOrderType: initialOrderType,
            initialIntervalType: initialIntervalType
        )

        marketCapFormatter = .init(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )

        headerViewModel = MarketsSearchHeaderViewModel()
        marketsRatingHeaderViewModel = MarketsRatingHeaderViewModel(provider: filterProvider)

        tokenListViewModel = MarketsTokenListViewModel(
            listDataProvider: dataProvider,
            listDataFilterProvider: filterProvider,
            quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper,
            quotesUpdatesScheduler: quotesUpdatesScheduler,
            chartsHistoryProvider: chartsHistoryProvider,
            coordinator: coordinator
        )

        bindChildViewModels()

        searchTextBind(publisher: headerViewModel.enteredSearchInputPublisher, scheduler: searchInputScheduler)
        searchFilterBind(filterPublisher: filterProvider.filterPublisher)

        searchFocusBind()
    }

    deinit {
        AppLogger.debug("MarketsSearchViewModel deinit")
    }

    func onViewAppear() {
        tokenListViewModel.resumeQuotesUpdates()
    }

    func onViewDisappear() {
        tokenListViewModel.pauseQuotesUpdates()
    }
}

// MARK: - Private Implementation

private extension MarketsSearchViewModel {
    func bindChildViewModels() {
        tokenListViewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
    }

    func reset() {
        tokenListViewModel.onResetShowItemsBelowCapFlag()
        currentSearchValue = ""
        tokenListViewModel.onFetch(with: "", by: filterProvider.currentFilterValue)
    }

    func searchFocusBind() {
        headerViewModel.$inputShouldBecomeFocused
            .withWeakCaptureOf(self)
            .sink { viewModel, isFocused in
                viewModel.isSearchFieldFocused = isFocused

                guard isFocused, !viewModel.isSearching else { return }

                Analytics.log(.marketsTokenSearchedClicked)
                viewModel.isSearching = true
            }
            .store(in: &bag)
    }

    private func searchTextBind(publisher: some Publisher<SearchInput, Never>, scheduler: some Scheduler) {
        publisher
            .dropFirst()
            .debounce(for: .seconds(Constants.searchInputDebounceInterval), scheduler: scheduler)
            .filter { searchInput in
                if case .textInput = searchInput { true } else { false }
            }
            // Ensure that clear and cancel input events will be delivered immediately
            .merge(with: publisher.filter { $0 == .clearInput || $0 == .cancelInput })
            .removeDuplicates { lhs, rhs in
                switch (lhs, rhs) {
                case (.textInput(let lhsValue), .textInput(let rhsValue)):
                    return lhsValue == rhsValue
                default:
                    return false
                }
            }
            .withWeakCaptureOf(self)
            .sink { viewModel, searchInput in
                switch searchInput {
                case .textInput(let value):
                    if viewModel.currentSearchValue.compare(value) != .orderedSame {
                        viewModel.tokenListViewModel.onResetShowItemsBelowCapFlag()
                    }

                    viewModel.currentSearchValue = value
                    let currentFilter = viewModel.dataProvider.lastFilterValue ?? viewModel.filterProvider.currentFilterValue

                    // Always use rating sorting for search
                    let searchFilter = MarketsListDataProvider.Filter(
                        interval: currentFilter.interval,
                        order: value.isEmpty ? currentFilter.order : .rating
                    )

                    viewModel.tokenListViewModel.onFetch(with: value, by: searchFilter)
                case .clearInput:
                    if viewModel.currentSearchValue.isEmpty {
                        return
                    }

                    viewModel.reset()
                case .cancelInput:
                    viewModel.isSearching = false
                    viewModel.reset()
                }
            }
            .store(in: &bag)
    }

    func searchFilterBind(filterPublisher: (some Publisher<MarketsListDataProvider.Filter, Never>)?) {
        filterPublisher?
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                // If we change the sorting, we always rebuild the list.
                guard value.order == viewModel.dataProvider.lastFilterValue?.order else {
                    viewModel.tokenListViewModel.onFetch(
                        with: viewModel.dataProvider.lastSearchTextValue ?? "",
                        by: viewModel.filterProvider.currentFilterValue
                    )
                    return
                }

                // If the sorting value has not changed, and order filter for losers or gainers or buyers, the order of the list may also change.
                // Otherwise, we just get new charts for a given interval.
                // The charts will also be updated when the list is updated
                if Constants.filterRequiredReloadInterval.contains(value.order) {
                    viewModel.tokenListViewModel.onFetch(
                        with: viewModel.dataProvider.lastSearchTextValue ?? "",
                        by: viewModel.filterProvider.currentFilterValue
                    )
                } else {
                    let hotAreaRange = viewModel.tokenListViewModel.listDataControllerHotArea
                    viewModel.tokenListViewModel.onRequestMiniCharts(forRange: hotAreaRange.range, interval: value.interval)
                }
            }
            .store(in: &bag)
    }
}

private extension MarketsSearchViewModel {
    enum Constants {
        static let searchInputDebounceInterval: Double = 0.5
        static let filterRequiredReloadInterval: Set<MarketsListOrderType> = [.buyers, .gainers, .losers]
    }
}
