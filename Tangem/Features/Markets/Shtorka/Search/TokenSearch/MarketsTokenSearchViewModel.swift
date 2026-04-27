//
//  MarketsTokenSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization

final class MarketsTokenSearchViewModel: ObservableObject {
    // MARK: - Published states

    @Published private(set) var state: State = .idle
    @Published private(set) var recentState: RecentState?
    @Published private(set) var searchState: SearchState?

    // MARK: - Injections

    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

    // MARK: - Dependencies

    private let headerViewModel: MainBottomSheetHeaderViewModel
    private let tokenListViewModel: MarketsTokenListViewModel
    private let chartsHistoryProvider: MarketsListChartsHistoryProvider
    private let filterProvider: MarketsListDataFilterProvider

    private weak var coordinator: MarketsRoutable?

    // MARK: - Private properties

    private let walletModelsAggregator: WalletModelsAggregator = CommonWalletModelsAggregator()

    private let marketCapFormatter = MarketCapFormatter(
        divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
        baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
        notationFormatter: DefaultAmountNotationFormatter()
    )

    private lazy var storage: any MarketsTokenSearchStorage = CommonMarketsTokenSearchStorage(
        persistentStorage: persistentStorage
    )

    private let portfolioStateSubject = PassthroughSubject<PortfolioState, Never>()
    private let marketStateSubject = PassthroughSubject<MarketState, Never>()

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        headerViewModel: MainBottomSheetHeaderViewModel,
        tokenListViewModel: MarketsTokenListViewModel,
        chartsHistoryProvider: MarketsListChartsHistoryProvider,
        filterProvider: MarketsListDataFilterProvider,
        coordinator: MarketsRoutable?
    ) {
        self.headerViewModel = headerViewModel
        self.tokenListViewModel = tokenListViewModel
        self.chartsHistoryProvider = chartsHistoryProvider
        self.filterProvider = filterProvider
        self.coordinator = coordinator

        bind()
    }
}

// MARK: - Private methods

private extension MarketsTokenSearchViewModel {
    func bind() {
        headerViewModel.$inputShouldBecomeFocused
            .combineLatest(headerViewModel.$enteredSearchText)
            .compactMap { [weak self] isFocused, searchText in
                self?.makeState(isFocused: isFocused, searchText: searchText)
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$state)

        storage.recentItemsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, recentItems in
                viewModel.makeRecentState(items: recentItems)
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$recentState)

        portfolioStateSubject
            .combineLatest(marketStateSubject)
            .compactMap { [weak self] portfolioState, marketState in
                self?.makeSearchState(portfolioState: portfolioState, marketState: marketState)
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$searchState)

        walletModelsAggregator.walletModelsPublisher
            .combineLatest(headerViewModel.$enteredSearchText)
            .compactMap { [weak self] walletModels, searchText in
                self?.makePortfolioState(walletModels: walletModels, search: searchText)
            }
            .removeDuplicates()
            .subscribe(portfolioStateSubject)
            .store(in: &bag)

        tokenListViewModel.$tokenListLoadingState
            .combineLatest(tokenListViewModel.$tokenViewModels)
            .compactMap { [weak self] marketListLoadingState, marketItems in
                self?.makeMarketState(
                    marketListLoadingState: marketListLoadingState,
                    marketItems: marketItems
                )
            }
            .removeDuplicates()
            .subscribe(marketStateSubject)
            .store(in: &bag)

        headerViewModel.$enteredSearchText
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchText in
                viewModel.fetchMarketTokensIfNeeded(searchText: searchText)
            }
            .store(in: &bag)
    }

    func fetchMarketTokensIfNeeded(searchText: String) {
        let search = searchText.trimmed()

        guard search.isNotEmpty else {
            return
        }

        tokenListViewModel.onResetShowItemsBelowCapFlag()
        let filter = MarketsListDataProvider.Filter(interval: .day, order: .rating)
        tokenListViewModel.onFetch(with: search, by: filter)
    }
}

// MARK: - State

private extension MarketsTokenSearchViewModel {
    func makeState(isFocused: Bool, searchText: String) -> State {
        let search = searchText.trimmed()

        guard isFocused || search.isNotEmpty else {
            return .idle
        }

        return search.isEmpty ? .recent : .search
    }
}

// MARK: - RecentState

private extension MarketsTokenSearchViewModel {
    func makeRecentState(items: [MarketsTokenSearchRecentItem]) -> RecentState {
        var queries: [String] = []
        var marketTokens: [MarketTokenItemViewModel] = []

        for item in items {
            switch item {
            case .query(let text):
                queries.append(text)

            case .marketAsset(let tokenModel):
                marketTokens.append(makeMarketTokenItemViewModel(for: tokenModel))
            }
        }

        guard queries.isNotEmpty || marketTokens.isNotEmpty else {
            return .empty
        }

        let item = RecentItem(
            queries: queries,
            marketTokens: marketTokens,
            onQuery: { [weak self] query in
                self?.onRecentQuery(query)
            },
            onClearAll: { [weak self] in
                self?.onRecentClearAll()
            }
        )

        return .item(item)
    }

    func makeMarketTokenItemViewModel(for tokenModel: MarketsTokenModel) -> MarketTokenItemViewModel {
        MarketTokenItemViewModel(
            tokenModel: tokenModel,
            marketCapFormatter: marketCapFormatter,
            chartsProvider: chartsHistoryProvider,
            filterProvider: filterProvider,
            onTapAction: { [weak self] in
                self?.onRecentMarketToken(tokenModel)
            }
        )
    }

    func onRecentMarketToken(_ tokenModel: MarketsTokenModel) {
        let query = headerViewModel.enteredSearchText.trimmed()
        Task {
            if query.isNotEmpty {
                await storage.saveQuery(query)
            }
            await storage.saveMarketAsset(tokenModel)
        }
        coordinator?.openMarketsTokenDetails(for: tokenModel)
    }

    func onRecentQuery(_ query: String) {
        headerViewModel.enteredSearchText = query
    }

    func onRecentClearAll() {
        Task {
            await storage.clearAll()
        }
    }
}

// MARK: - SearchState

private extension MarketsTokenSearchViewModel {
    func makeSearchState(portfolioState: PortfolioState, marketState: MarketState) -> SearchState {
        if portfolioState == .empty, marketState == .empty {
            let item = SearchEmptyItem(title: Localization.commonNoResults)
            return .empty(item)
        }
        return .result(portfolio: portfolioState, market: marketState)
    }
}

// MARK: - PortfolioState

private extension MarketsTokenSearchViewModel {
    func makePortfolioState(walletModels: [any WalletModel], search: String) -> PortfolioState {
        let trimmedSearch = search.trimmed()

        let filteredWalletModels = walletModels.filter { walletModel in
            let item = walletModel.tokenItem
            return item.name.caseInsensitiveContains(trimmedSearch) || item.currencySymbol.caseInsensitiveContains(trimmedSearch)
        }

        guard filteredWalletModels.isNotEmpty else {
            return .empty
        }

        let item = PortfolioItem(
            title: Localization.marketsSearchPortfolioHeader,
            walletModels: filteredWalletModels,
            onSingleToken: { [weak self] in
                self?.onPortfolioToken()
                // [REDACTED_TODO_COMMENT]
            },
            onMultipleToken: {
                // [REDACTED_TODO_COMMENT]
            }
        )

        return .item(item)
    }

    func onPortfolioToken() {
        let query = headerViewModel.enteredSearchText.trimmed()
        if query.isNotEmpty {
            Task { await storage.saveQuery(query) }
        }
    }
}

// MARK: - MarketState

private extension MarketsTokenSearchViewModel {
    func makeMarketState(
        marketListLoadingState: MarketsView.ListLoadingState,
        marketItems: [MarketsItemViewModel]
    ) -> MarketState {
        // [REDACTED_TODO_COMMENT]
        return .empty
    }
}

// MARK: - Types

extension MarketsTokenSearchViewModel {
    enum State {
        case idle
        case recent
        case search
    }

    enum RecentState: Equatable {
        case empty
        case item(RecentItem)
    }

    struct RecentItem: Equatable {
        let id = UUID()
        let queries: [String]
        let marketTokens: [MarketTokenItemViewModel]
        let onQuery: (String) -> Void
        let onClearAll: () -> Void

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }

    enum SearchState: Equatable {
        case empty(SearchEmptyItem)
        case result(portfolio: PortfolioState, market: MarketState)
    }

    struct SearchEmptyItem: Equatable {
        let title: String
    }

    enum PortfolioState: Equatable {
        case empty
        case item(PortfolioItem)
    }

    struct PortfolioItem: Equatable {
        let title: String
        let walletModels: [any WalletModel]
        let onSingleToken: () -> Void
        let onMultipleToken: () -> Void

        static func == (lhs: Self, rhs: Self) -> Bool {
            Set(lhs.walletModels.map(\.id)) == Set(rhs.walletModels.map(\.id))
        }
    }

    enum MarketState: Equatable {
        case loading
        case empty
        case item(MarketItem)
        case retry(MarketRetryItem)
    }

    struct MarketItem: Equatable {
        let title: String
        let onTap: () -> Void

        static func == (lhs: Self, rhs: Self) -> Bool {
            // [REDACTED_TODO_COMMENT]
            lhs.title == rhs.title
        }
    }

    struct MarketRetryItem: Equatable {
        // [REDACTED_TODO_COMMENT]
    }
}
