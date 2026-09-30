//
//  CryptoSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class CryptoSearchViewModel: ObservableObject {
    @Published private(set) var query: String = ""
    @Published private(set) var portfolio: MarketsPortfolioTokenListViewModel?
    @Published private(set) var markets: MarketsState = .loading
    @Published private var isVisible = false

    private let searchesOnEmptyQuery: Bool
    private let history: FeedSearchHistoryProvider
    private let marketsProvider: any FeedSearchProvider<MarketsTokenModel>
    private let router: any CryptoFeedRoutable
    private let portfolioProvider: FeedSearchPortfolioProvider

    private let rowsProvider = MarketTokenRowsProvider(filterProvider: MarketsListDataFilterProvider(initialIntervalType: .day))

    private var rowViewModels: [String: MarketTokenItemViewModel] = [:]
    private var visibleResultIDs: Set<String> = []

    private var tokens: [MarketsTokenModel] = []
    private var showsTokensUnderCap = false
    private var requestedQuery: String?
    private var loadedQuery: String?
    private var bag = Set<AnyCancellable>()

    init(
        query: AnyPublisher<String, Never>,
        searchesOnEmptyQuery: Bool = false,
        history: FeedSearchHistoryProvider,
        router: any CryptoFeedRoutable,
        marketsProvider: any FeedSearchProvider<MarketsTokenModel> = MarketsFeedSearchProvider(),
        portfolioProvider: FeedSearchPortfolioProvider = FeedSearchPortfolioProvider()
    ) {
        self.searchesOnEmptyQuery = searchesOnEmptyQuery
        self.history = history
        self.router = router
        self.portfolioProvider = portfolioProvider
        self.marketsProvider = marketsProvider

        bind(to: query)
    }

    deinit {
        AppLogger.debug("CryptoSearchViewModel deinit")
    }

    func setVisible(_ isVisible: Bool) {
        self.isVisible = isVisible
        loadMarketsIfNeeded()

        if isVisible {
            rowsProvider.resumeQuotes()
            rowsProvider.requestCharts()
        } else {
            rowsProvider.suspendQuotes()
        }
    }

    func onResultDisappear(_ row: MarketTokenItemViewModel) {
        visibleResultIDs.remove(row.tokenId)
        rowsProvider.setVisibleTokenIDs(visibleResultIDs)
    }

    func onResultAppear(_ row: MarketTokenItemViewModel) {
        visibleResultIDs.insert(row.tokenId)
        rowsProvider.setVisibleTokenIDs(visibleResultIDs)

        guard case .results(let rows, _) = markets, row.tokenId == rows.last?.tokenId, loadedQuery == query else {
            return
        }

        marketsProvider.loadMore()
    }

    func onShowTokensUnderCap() {
        showsTokensUnderCap = true
        markets = makeResultsState()
    }

    func onRetry() {
        loadedQuery = nil
        loadMarketsIfNeeded()
    }
}

// MARK: - Binding

private extension CryptoSearchViewModel {
    func bind(to query: AnyPublisher<String, Never>) {
        rowsProvider
            .currencyDidChangePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.reloadForCurrencyChange()
            }
            .store(in: &bag)

        let trimmedQuery = query
            .map { $0.trimmed() }
            .removeDuplicates()
            .share()

        trimmedQuery
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, query in
                viewModel.onQueryChange(query)
            }
            .store(in: &bag)

        trimmedQuery
            .debounce(for: Constants.marketsDebounce, scheduler: DispatchQueue.main)
            .filter { $0.isNotEmpty }
            .withWeakCaptureOf(self)
            .sink { viewModel, query in
                viewModel.requestedQuery = query
                viewModel.loadMarketsIfNeeded()
            }
            .store(in: &bag)

        portfolioProvider
            .portfolioPublisher(query: $query, isVisible: $isVisible) { [weak self] walletModel in
                self?.router.openPortfolioToken(walletModel)
            }
            .withWeakCaptureOf(self)
            .sink { viewModel, portfolio in
                viewModel.portfolio = portfolio
            }
            .store(in: &bag)

        marketsProvider
            .statePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.apply(state)
            }
            .store(in: &bag)
    }
}

// MARK: - Query

private extension CryptoSearchViewModel {
    func onQueryChange(_ query: String) {
        self.query = query
        showsTokensUnderCap = false
        requestedQuery = nil
        guard query.isNotEmpty else {
            rowViewModels.removeAll()
            visibleResultIDs.removeAll()
            rowsProvider.setVisibleTokenIDs([])
            loadedQuery = nil
            tokens = []
            markets = .loading
            marketsProvider.reset()
            if searchesOnEmptyQuery {
                requestedQuery = query
                loadMarketsIfNeeded()
            }
            return
        }

        if case .results = markets {
            return
        }

        markets = .loading
    }

    func loadMarketsIfNeeded() {
        guard isVisible, let requestedQuery, requestedQuery != loadedQuery else {
            return
        }

        loadedQuery = requestedQuery
        marketsProvider.search(requestedQuery)
    }
}

// MARK: - Markets

private extension CryptoSearchViewModel {
    func apply(_ state: FeedSearchProviderState<MarketsTokenModel>) {
        guard query.isNotEmpty || searchesOnEmptyQuery else {
            return
        }

        switch state {
        case .loading:
            if case .results = markets {
                return
            }

            markets = .loading

        case .loaded(let tokens):
            self.tokens = tokens
            let ids = Set(tokens.map(\.id))
            rowViewModels = rowViewModels.filter { ids.contains($0.key) }
            visibleResultIDs.formIntersection(ids)
            rowsProvider.updateQuotes(for: tokens)
            rowsProvider.setVisibleTokenIDs(visibleResultIDs)
            markets = makeResultsState()

        case .empty:
            tokens = []
            markets = .empty

        case .failed:
            tokens = []
            markets = .failed
        }
    }

    func makeResultsState() -> MarketsState {
        let visible = query.isEmpty || showsTokensUnderCap ? tokens : tokens.filter { !($0.isUnderMarketCapLimit ?? false) }

        return .results(visible.map(makeRow(for:)), hasTokensUnderCap: visible.count != tokens.count)
    }

    /// Prices and market caps come from the search response in the selected currency, so the whole query
    /// has to be asked again rather than reformatted from the snapshot taken in the previous one.
    func reloadForCurrencyChange() {
        rowViewModels.removeAll()

        guard let loadedQuery else {
            return
        }

        self.loadedQuery = nil
        requestedQuery = loadedQuery
        loadMarketsIfNeeded()
    }

    func makeRow(for model: MarketsTokenModel) -> MarketTokenItemViewModel {
        if let row = rowViewModels[model.id] {
            row.updateRestriction(from: model)
            return row
        }

        let row = rowsProvider.makeRowViewModel(for: model) { [weak self] in
            guard let self else { return }

            let model = tokens.first { $0.id == model.id } ?? model
            history.save(query: query)
            router.openToken(model)
        }

        rowViewModels[model.id] = row
        return row
    }
}

// MARK: - Types

extension CryptoSearchViewModel {
    enum MarketsState {
        case loading
        case results([MarketTokenItemViewModel], hasTokensUnderCap: Bool)
        case empty
        case failed
    }
}

// MARK: - Constants

private extension CryptoSearchViewModel {
    enum Constants {
        static let marketsDebounce: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500)
    }
}
