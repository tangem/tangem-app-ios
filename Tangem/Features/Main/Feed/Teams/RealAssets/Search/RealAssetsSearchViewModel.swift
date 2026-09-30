//
//  RealAssetsSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class RealAssetsSearchViewModel: ObservableObject {
    @Published private(set) var query: String = ""
    @Published private(set) var portfolio: MarketsPortfolioTokenListViewModel?
    @Published private(set) var assets: AssetsState = .loading
    @Published private var isVisible = false

    private let history: FeedSearchHistoryProvider
    private let assetsProvider: any FeedSearchProvider<MarketsTokenModel>
    private let router: any RealAssetsFeedRoutable
    private let portfolioProvider: FeedSearchPortfolioProvider

    private let rowsProvider = MarketTokenRowsProvider(filterProvider: MarketsListDataFilterProvider(initialIntervalType: .day))

    private var rowViewModels: [String: MarketTokenItemViewModel] = [:]
    private var visibleResultIDs: Set<String> = []

    private var tokens: [MarketsTokenModel] = []
    private var requestedQuery: String?
    private var loadedQuery: String?
    private var bag = Set<AnyCancellable>()

    init(
        query: AnyPublisher<String, Never>,
        history: FeedSearchHistoryProvider,
        router: any RealAssetsFeedRoutable,
        assetsProvider: any FeedSearchProvider<MarketsTokenModel> = RealAssetsFeedSearchProvider(),
        portfolioProvider: FeedSearchPortfolioProvider = FeedSearchPortfolioProvider()
    ) {
        self.history = history
        self.router = router
        self.portfolioProvider = portfolioProvider
        self.assetsProvider = assetsProvider

        bind(to: query)
    }

    deinit {
        AppLogger.debug("RealAssetsSearchViewModel deinit")
    }

    func setVisible(_ isVisible: Bool) {
        self.isVisible = isVisible
        loadAssetsIfNeeded()

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

        guard case .results(let rows) = assets, row.tokenId == rows.last?.tokenId, loadedQuery == query else {
            return
        }

        assetsProvider.loadMore()
    }

    func onRetry() {
        loadedQuery = nil
        loadAssetsIfNeeded()
    }
}

// MARK: - Binding

private extension RealAssetsSearchViewModel {
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
            .debounce(for: Constants.assetsDebounce, scheduler: DispatchQueue.main)
            .filter { $0.isNotEmpty }
            .withWeakCaptureOf(self)
            .sink { viewModel, query in
                viewModel.requestedQuery = query
                viewModel.loadAssetsIfNeeded()
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

        assetsProvider
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

private extension RealAssetsSearchViewModel {
    func onQueryChange(_ query: String) {
        self.query = query
        requestedQuery = nil

        guard query.isNotEmpty else {
            rowViewModels.removeAll()
            visibleResultIDs.removeAll()
            rowsProvider.setVisibleTokenIDs([])
            loadedQuery = nil
            tokens = []
            assets = .loading
            assetsProvider.reset()
            return
        }

        if case .results = assets {
            return
        }

        loadedQuery = nil
        assets = .loading
    }

    func loadAssetsIfNeeded() {
        guard isVisible, let requestedQuery, requestedQuery != loadedQuery else {
            return
        }

        loadedQuery = requestedQuery
        assetsProvider.search(requestedQuery)
    }
}

// MARK: - Assets

private extension RealAssetsSearchViewModel {
    func apply(_ state: FeedSearchProviderState<MarketsTokenModel>) {
        guard query.isNotEmpty else {
            return
        }

        switch state {
        case .loading:
            if case .results = assets {
                return
            }

            assets = .loading

        case .loaded(let tokens):
            self.tokens = tokens
            let ids = Set(tokens.map(\.id))
            rowViewModels = rowViewModels.filter { ids.contains($0.key) }
            visibleResultIDs.formIntersection(ids)
            rowsProvider.updateQuotes(for: tokens)
            rowsProvider.setVisibleTokenIDs(visibleResultIDs)
            assets = .results(tokens.map(makeRow(for:)))

        case .empty:
            tokens = []
            assets = .empty

        case .failed:
            tokens = []
            assets = .failed
        }
    }

    func reloadForCurrencyChange() {
        rowViewModels.removeAll()

        guard let loadedQuery else {
            return
        }

        self.loadedQuery = nil
        requestedQuery = loadedQuery
        loadAssetsIfNeeded()
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

extension RealAssetsSearchViewModel {
    enum AssetsState {
        case loading
        case results([MarketTokenItemViewModel])
        case empty
        case failed
    }
}

// MARK: - Constants

private extension RealAssetsSearchViewModel {
    enum Constants {
        static let assetsDebounce: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500)
    }
}
