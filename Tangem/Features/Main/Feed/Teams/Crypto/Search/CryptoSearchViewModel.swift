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
    @Published private(set) var portfolio: MarketsPortfolioTokenSearchViewModel?
    @Published private(set) var markets: MarketsState = .loading

    private let history: FeedSearchHistoryProvider
    private let marketsProvider: any FeedSearchProvider<MarketsTokenModel>
    private let router: any CryptoFeedRoutable

    private let walletModelsAggregator: WalletModelsAggregator = CommonWalletModelsAggregator()
    private let priceFormatter = MarketsTokenPriceFormatter()
    private let percentFormatter = PercentFormatter()
    private let iconURLBuilder = IconURLBuilder()

    private var tokens: [MarketsTokenModel] = []
    private var isVisible = false
    private var showsTokensUnderCap = false
    private var requestedQuery: String?
    private var loadedQuery: String?
    private var bag = Set<AnyCancellable>()

    init(
        query: AnyPublisher<String, Never>,
        history: FeedSearchHistoryProvider,
        router: any CryptoFeedRoutable,
        marketsProvider: any FeedSearchProvider<MarketsTokenModel> = MarketsFeedSearchProvider()
    ) {
        self.history = history
        self.router = router
        self.marketsProvider = marketsProvider

        bind(to: query)
    }

    deinit {
        AppLogger.debug("CryptoSearchViewModel deinit")
    }

    func setVisible(_ isVisible: Bool) {
        self.isVisible = isVisible
        loadMarketsIfNeeded()
    }

    func onSelectResult(_ result: CryptoSearchResult) {
        history.save(token: result.model)
        history.save(query: query)
        router.openToken(result.model)
    }

    func onResultAppear(_ result: CryptoSearchResult) {
        guard case .results(let results, _) = markets, result.id == results.last?.id, loadedQuery == query else {
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

        $query
            .combineLatest(walletModelsAggregator.walletModelsPublisher)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, input in
                let (query, walletModels) = input
                viewModel.portfolio = viewModel.makePortfolio(query: query, walletModels: walletModels)
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
            loadedQuery = nil
            tokens = []
            markets = .loading
            marketsProvider.reset()
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

// MARK: - Portfolio

private extension CryptoSearchViewModel {
    func makePortfolio(query: String, walletModels: [any WalletModel]) -> MarketsPortfolioTokenSearchViewModel? {
        guard query.isNotEmpty else {
            return nil
        }

        let matches = walletModels.filter { walletModel in
            let item = walletModel.tokenItem
            return item.name.caseInsensitiveContains(query) || item.currencySymbol.caseInsensitiveContains(query)
        }

        guard matches.isNotEmpty else {
            return nil
        }

        return MarketsPortfolioTokenSearchViewModel(
            walletModels: matches,
            onSingleToken: { [weak self] walletModel in
                self?.router.openPortfolioToken(walletModel)
            },
            onMultipleToken: { [weak self] walletModels in
                if walletModels.count == 1, let walletModel = walletModels.first {
                    self?.router.openPortfolioToken(walletModel)
                } else {
                    self?.router.choosePortfolioToken(from: walletModels)
                }
            }
        )
    }
}

// MARK: - Markets

private extension CryptoSearchViewModel {
    func apply(_ state: FeedSearchProviderState<MarketsTokenModel>) {
        guard query.isNotEmpty else {
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
        let visible = showsTokensUnderCap ? tokens : tokens.filter { !($0.isUnderMarketCapLimit ?? false) }

        return .results(visible.map(makeResult(from:)), hasTokensUnderCap: visible.count != tokens.count)
    }

    func makeResult(from model: MarketsTokenModel) -> CryptoSearchResult {
        let change = model.priceChangePercentage[MarketsPriceIntervalType.day.marketsListId] as? Decimal ?? 0

        return CryptoSearchResult(
            id: model.id,
            name: model.name,
            symbol: model.symbol.uppercased(),
            price: priceFormatter.formatPrice(model.currentPrice),
            change: percentFormatter.format(change / 100, option: .priceChange),
            isPositive: change >= 0,
            icon: .remote(name: model.name, imageURL: iconURLBuilder.tokenIconURL(id: model.id)),
            model: model
        )
    }
}

// MARK: - Types

extension CryptoSearchViewModel {
    enum MarketsState {
        case loading
        case results([CryptoSearchResult], hasTokensUnderCap: Bool)
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
