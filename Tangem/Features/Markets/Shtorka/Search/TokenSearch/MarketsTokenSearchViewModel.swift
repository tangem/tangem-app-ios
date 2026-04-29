//
//  MarketsTokenSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import class UIKit.UIApplication
import TangemFoundation
import TangemUIUtils
import TangemLocalization

final class MarketsTokenSearchViewModel: ObservableObject {
    // MARK: - Published states

    @Published private(set) var state: State = .idle
    @Published private(set) var recentState: RecentState = .idle
    @Published private(set) var portfolioState: PortfolioState = .idle
    @Published private(set) var marketItem: MarketItem?

    // MARK: - Computed properties

    var isSearchEmpty: Bool {
        guard let marketItem else { return false }
        return portfolioState == .empty && marketItem.state == .empty
    }

    let searchEmptyTitle = Localization.commonNoResults

    // MARK: - Injections

    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Dependencies

    private let headerViewModel: MainBottomSheetHeaderViewModel
    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper

    private weak var coordinator: MarketsTokenSearchRoutable?

    // MARK: - Private properties

    private let walletModelsAggregator: WalletModelsAggregator = CommonWalletModelsAggregator()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private let filterProvider = MarketsListDataFilterProvider()

    private let marketCapFormatter = MarketCapFormatter(
        divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
        baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
        notationFormatter: DefaultAmountNotationFormatter()
    )

    private lazy var storage: any MarketsTokenSearchStorage = CommonMarketsTokenSearchStorage(
        persistentStorage: persistentStorage
    )

    private lazy var tokenListViewModel = MarketsTokenListViewModel(
        listDataProvider: MarketsListDataProvider(),
        listDataFilterProvider: filterProvider,
        quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper,
        quotesUpdatesScheduler: MarketsQuotesUpdatesScheduler(),
        chartsHistoryProvider: chartsHistoryProvider,
        coordinator: self
    )

    private let searchDebounceMs: Int = 300
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        headerViewModel: MainBottomSheetHeaderViewModel,
        quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper,
        coordinator: MarketsTokenSearchRoutable?
    ) {
        self.headerViewModel = headerViewModel
        self.quotesRepositoryUpdateHelper = quotesRepositoryUpdateHelper
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
            .receiveOnMain()
            .assign(to: &$recentState)

        walletModelsAggregator.walletModelsPublisher
            .combineLatest(headerViewModel.$enteredSearchText)
            .compactMap { [weak self] walletModels, searchText in
                self?.makePortfolioState(walletModels: walletModels, search: searchText)
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$portfolioState)

        tokenListViewModel.$tokenViewModels
            .combineLatest(tokenListViewModel.$tokenListLoadingState)
            .compactMap { [weak self] tokenViewModels, tokenListLoadingState in
                self?.makeMarketItem(
                    models: tokenViewModels,
                    loadingState: tokenListLoadingState
                )
            }
            .receiveOnMain()
            .assign(to: &$marketItem)

        headerViewModel.$enteredSearchText
            .debounce(for: .milliseconds(searchDebounceMs), scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, searchText in
                viewModel.fetchMarketTokensIfNeeded(searchText: searchText)
            }
            .store(in: &bag)
    }

    func hideKeyboard() {
        headerViewModel.lostInputFocus()
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
        storeRecentMarket(tokenModel: tokenModel)
        openMarketsTokenDetails(tokenModel: tokenModel)
    }

    func onRecentQuery(_ query: String) {
        headerViewModel.enteredSearchText = query
    }

    func onRecentClearAll() {
        clearRecentStorage()
    }
}

// MARK: - Recent storage

private extension MarketsTokenSearchViewModel {
    func storeRecentMarket(tokenModel: MarketsTokenModel) {
        storeRecentQuery()
        Task {
            await storage.saveMarketAsset(tokenModel)
        }
    }

    func storeRecentQuery() {
        let query = headerViewModel.enteredSearchText.trimmed()
        if query.isNotEmpty {
            Task { await storage.saveQuery(query) }
        }
    }

    func clearRecentStorage() {
        Task {
            await storage.clearAll()
        }
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

        let item = makePortfolioItem(walletModels: filteredWalletModels)
        return .item(item)
    }

    func makePortfolioItem(walletModels: [any WalletModel]) -> PortfolioItem {
        let model = MarketsPortfolioTokenSearchViewModel(
            walletModels: walletModels,
            onSingleToken: { [weak self] walletModel in
                self?.onPortfolioToken(walletModel: walletModel)
            },
            onMultipleToken: { [weak self] walletModels in
                self?.hideKeyboard()
                self?.openPortfolioTokenList(walletModels: walletModels)
            }
        )

        return PortfolioItem(title: Localization.marketsSearchPortfolioHeader, model: model)
    }

    func onPortfolioToken(walletModel: any WalletModel) {
        storeRecentQuery()

        if
            let userWalletModel = userWalletRepository.models[walletModel.userWalletId],
            let accountModel = walletModel.account {
            openTokenDetails(
                userWalletModel: userWalletModel,
                accountModel: accountModel,
                walletModel: walletModel
            )
        }
    }
}

// MARK: - MarketState

private extension MarketsTokenSearchViewModel {
    func makeMarketItem(
        models: [MarketsItemViewModel],
        loadingState: MarketsView.ListLoadingState
    ) -> MarketItem {
        let state: MarketState = makeMarketState(loadingState)

        let underCapItem = MarketItem.UnderCapItem(
            isShown: tokenListViewModel.shouldDisplayShowTokensUnderCapView,
            action: weakify(self, forFunction: MarketsTokenSearchViewModel.onMarketUnderCap)
        )

        let retryItem = MarketItem.RetryItem(
            action: weakify(self, forFunction: MarketsTokenSearchViewModel.onMarketRetry)
        )

        return MarketItem(
            title: Localization.marketsCommonTitle,
            state: state,
            models: models,
            underCapItem: underCapItem,
            retryItem: retryItem
        )
    }

    func makeMarketState(_ loadingState: MarketsView.ListLoadingState) -> MarketState {
        switch loadingState {
        case .idle: .idle
        case .loading: .loading
        case .allDataLoaded: .loaded
        case .noResults: .empty
        case .error: .retry
        }
    }

    func onMarketUnderCap() {
        tokenListViewModel.onShowUnderCapAction()
    }

    func onMarketRetry() {
        tokenListViewModel.onTryLoadList()
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

// MARK: - Navigation

private extension MarketsTokenSearchViewModel {
    func openTokenDetails(
        userWalletModel: UserWalletModel,
        accountModel: any CryptoAccountModel,
        walletModel: any WalletModel
    ) {
        Task { @MainActor [coordinator] in
            coordinator?.openPortfolioTokenDetails(
                userWalletModel: userWalletModel,
                accountModel: accountModel,
                walletModel: walletModel
            )
        }
    }

    func openMarketsTokenDetails(tokenModel: MarketsTokenModel) {
        Task { @MainActor [coordinator] in
            coordinator?.openMarketsTokenDetails(for: tokenModel)
        }
    }

    func openPortfolioTokenList(walletModels: [any WalletModel]) {
        Task { @MainActor [coordinator] in
            coordinator?.openPortfolioTokenList(
                walletModels: walletModels,
                onSelect: { [weak self] walletModel in
                    self?.onPortfolioToken(walletModel: walletModel)
                }
            )
        }
    }
}

// MARK: - MarketsRoutable

extension MarketsTokenSearchViewModel: MarketsRoutable {
    func openMarketsTokenDetails(for tokenModel: MarketsTokenModel) {
        storeRecentMarket(tokenModel: tokenModel)
        openMarketsTokenDetails(tokenModel: tokenModel)
    }

    func openFilterOrderBottonSheet(with provider: MarketsListDataFilterProvider) {
        // Not needed
    }
}

// MARK: - Types

extension MarketsTokenSearchViewModel {
    enum State {
        case idle
        case recent
        case search
    }

    enum RecentState {
        case idle
        case empty
        case item(RecentItem)
    }

    struct RecentItem {
        let queries: [String]
        let marketTokens: [MarketTokenItemViewModel]
        let onQuery: (String) -> Void
        let onClearAll: () -> Void
    }

    enum PortfolioState: Equatable {
        case idle
        case empty
        case item(PortfolioItem)
    }

    struct PortfolioItem: Equatable {
        let title: String
        let model: MarketsPortfolioTokenSearchViewModel

        static func == (lhs: Self, rhs: Self) -> Bool {
            Set(lhs.model.walletModelIds) == Set(rhs.model.walletModelIds)
        }
    }

    struct MarketItem {
        let title: String
        let state: MarketState
        let models: [MarketsItemViewModel]
        let underCapItem: UnderCapItem
        let retryItem: RetryItem

        struct UnderCapItem {
            let isShown: Bool
            let action: () -> Void
        }

        struct RetryItem {
            let action: () -> Void
        }
    }

    enum MarketState {
        case idle
        case empty
        case loading
        case loaded
        case retry
    }
}
