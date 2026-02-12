//
//  SwapMarketsTokensViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization

final class SwapMarketsTokensViewModel: ObservableObject {
    // MARK: - Published

    @Published private(set) var state: State = .loading

    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let dataProvider: MarketsListDataProvider
    private let chartsProvider: MarketsListChartsHistoryProvider
    private let filterProvider: MarketsListDataFilterProvider
    private let marketCapFormatter: MarketCapFormatter

    private lazy var listDataController: MarketsListDataController = .init(dataFetcher: self, cellsStateUpdater: nil)

    private var bag = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable?

    private weak var selectionHandler: SwapMarketsTokenSelectionHandler?

    private var currentSearchText: String = ""
    private var tokenViewModels: [MarketsItemViewModel] = []
    private var hasLoadedInitially = false

    // MARK: - Computed

    var isSearching: Bool {
        !currentSearchText.isEmpty
    }

    // MARK: - Init

    init(dataProvider: MarketsListDataProvider = MarketsListDataProvider(loadNetworks: true)) {
        self.dataProvider = dataProvider

        chartsProvider = MarketsListChartsHistoryProvider()
        filterProvider = MarketsListDataFilterProvider()
        marketCapFormatter = MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: .init()
        )

        bindToDataProvider()
    }

    // MARK: - Setup

    func setup(searchTextPublisher: some Publisher<String, Never>) {
        searchCancellable = searchTextPublisher
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.handleSearchTextChange(text)
            }
    }

    func setup(selectionHandler: SwapMarketsTokenSelectionHandler?) {
        self.selectionHandler = selectionHandler
    }

    func onAppear() {
        // Load initial list on first appear if no search text and not already loaded
        guard !hasLoadedInitially, currentSearchText.isEmpty else { return }

        hasLoadedInitially = true
        loadInitial()
    }

    func onRetry() {
        state = .loading
        if currentSearchText.isEmpty {
            loadInitial()
        } else {
            performSearch(text: currentSearchText)
        }
    }

    // MARK: - Private

    private func bindToDataProvider() {
        dataProvider.$lastEvent
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, event in
                viewModel.handleDataProviderEvent(event)
            }
            .store(in: &bag)
    }

    private func handleDataProviderEvent(_ event: MarketsListDataProvider.Event) {
        switch event {
        case .loading:
            if tokenViewModels.isEmpty {
                state = .loading
            } else {
                // Loading more - show isLoadingMore indicator
                state = .loaded(tokens: tokenViewModels, isSearching: isSearching, isLoadingMore: true)
            }
        case .startInitialFetch, .cleared:
            tokenViewModels = []
            state = .loading
        case .appendedItems(let items, _):
            let offset = tokenViewModels.count

            let availableItems = items.filter { $0.networks != nil }

            let newViewModels = availableItems.enumerated().compactMap { index, token in
                makeItemViewModel(token: token, index: offset + index)
            }
            tokenViewModels.append(contentsOf: newViewModels)

            // Fetch charts for new items
            let tokenIds = availableItems.map(\.id)
            chartsProvider.fetch(for: tokenIds, with: filterProvider.currentFilterValue.interval)

            if tokenViewModels.isEmpty {
                state = .noResults
            } else {
                state = .loaded(tokens: tokenViewModels, isSearching: isSearching, isLoadingMore: false)
            }
        case .failedToFetchData:
            if tokenViewModels.isEmpty {
                state = .error
            } else {
                // Keep showing current tokens, stop loading indicator
                state = .loaded(tokens: tokenViewModels, isSearching: isSearching, isLoadingMore: false)
            }
        case .idle:
            break
        }
    }

    private func handleSearchTextChange(_ text: String) {
        let previousSearchText = currentSearchText
        currentSearchText = text

        // If search text changed, reset the list
        if previousSearchText != text {
            dataProvider.reset()
            tokenViewModels = []
        }

        if text.isEmpty {
            loadInitial()
        } else {
            performSearch(text: text)
        }
    }

    private func loadInitial() {
        let filter = MarketsListDataProvider.Filter(interval: .day, order: .rating)
        dataProvider.fetch("", with: filter)
    }

    private func performSearch(text: String) {
        let filter = MarketsListDataProvider.Filter(interval: .day, order: .rating)
        dataProvider.fetch(text, with: filter)
    }

    private func makeItemViewModel(token: MarketsTokenModel, index: Int) -> MarketsItemViewModel? {
        guard let networks = token.networks,
              NetworkSupportChecker.hasAnySupportedNetwork(
                  networks: networks,
                  userWalletModels: userWalletRepository.models
              ) else {
            return nil
        }

        return MarketsItemViewModel(
            index: index,
            tokenModel: token,
            marketCapFormatter: marketCapFormatter,
            prefetchDataSource: listDataController,
            chartsProvider: chartsProvider,
            filterProvider: filterProvider,
            onTapAction: { [weak self] in
                self?.selectionHandler?.didSelectExternalToken(token)
            }
        )
    }
}

// MARK: - MarketsListDataFetcher

extension SwapMarketsTokensViewModel: MarketsListDataFetcher {
    var canFetchMore: Bool {
        dataProvider.canFetchMore
    }

    var totalItems: Int {
        tokenViewModels.count
    }

    func fetchMore() {
        dataProvider.fetchMore()
    }
}

// MARK: - State

extension SwapMarketsTokensViewModel {
    /// Returns true if markets section has visible content (loading or loaded with results)
    /// Used to determine if the parent view should hide its "no results" empty state
    var hasVisibleContent: Bool {
        switch state {
        case .noResults:
            return false
        case .loading, .loaded, .error:
            return true
        }
    }

    enum State: Equatable {
        case loading
        case loaded(tokens: [MarketsItemViewModel], isSearching: Bool, isLoadingMore: Bool)
        case noResults
        case error

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.noResults, .noResults), (.loading, .loading), (.error, .error):
                return true
            case (
                .loaded(let lhsTokens, let lhsSearching, let lhsLoadingMore),
                .loaded(let rhsTokens, let rhsSearching, let rhsLoadingMore)
            ):
                return lhsTokens.map(\.tokenId) == rhsTokens.map(\.tokenId)
                    && lhsSearching == rhsSearching
                    && lhsLoadingMore == rhsLoadingMore
            default:
                return false
            }
        }
    }
}

// MARK: - SwapMarketTokenSelectionHandler

protocol SwapMarketsTokenSelectionHandler: AnyObject {
    func didSelectExternalToken(_ token: MarketsTokenModel)
}
