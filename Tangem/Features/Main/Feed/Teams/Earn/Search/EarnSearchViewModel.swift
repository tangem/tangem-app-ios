//
//  EarnSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class EarnSearchViewModel: ObservableObject {
    @Published private(set) var query: String = ""
    @Published private(set) var portfolio: MarketsPortfolioTokenListViewModel?
    @Published private(set) var opportunities: OpportunitiesState = .loading
    @Published private var isVisible = false

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.earnAnalyticsProvider) private var analyticsProvider: EarnAnalyticsProvider

    private let searchProvider: any FeedSearchProvider<EarnTokenModel>
    private let router: any EarnFeedRoutable
    private let portfolioProvider: FeedSearchPortfolioProvider

    private let resolver = EarnTokenInWalletResolver()

    private var requestedQuery: String?
    private var loadedQuery: String?
    private var bag = Set<AnyCancellable>()

    private var userWalletModels: [UserWalletModel] {
        userWalletRepository.models.filter { !$0.isUserWalletLocked }
    }

    init(
        query: AnyPublisher<String, Never>,
        router: any EarnFeedRoutable,
        searchProvider: any FeedSearchProvider<EarnTokenModel> = EarnFeedSearchProvider(),
        portfolioProvider: FeedSearchPortfolioProvider = FeedSearchPortfolioProvider()
    ) {
        self.router = router
        self.portfolioProvider = portfolioProvider
        self.searchProvider = searchProvider

        bind(to: query)
    }

    deinit {
        AppLogger.debug("EarnSearchViewModel deinit")
    }

    func setVisible(_ isVisible: Bool) {
        self.isVisible = isVisible
        searchIfNeeded()
    }

    func onRetry() {
        loadedQuery = nil
        searchIfNeeded()
    }
}

// MARK: - Binding

private extension EarnSearchViewModel {
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
            .debounce(for: Constants.searchDebounce, scheduler: DispatchQueue.main)
            .filter { $0.isNotEmpty }
            .withWeakCaptureOf(self)
            .sink { viewModel, query in
                viewModel.requestedQuery = query
                viewModel.searchIfNeeded()
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

        searchProvider
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

private extension EarnSearchViewModel {
    func onQueryChange(_ query: String) {
        self.query = query
        requestedQuery = nil

        guard query.isNotEmpty else {
            loadedQuery = nil
            opportunities = .loading
            searchProvider.reset()
            return
        }

        if case .results = opportunities {
            return
        }

        // Going back to the skeleton has to re-run the search, even for a query that already loaded once.
        loadedQuery = nil
        opportunities = .loading
    }

    func searchIfNeeded() {
        guard isVisible, let requestedQuery, requestedQuery != loadedQuery else {
            return
        }

        loadedQuery = requestedQuery
        searchProvider.search(requestedQuery)
    }
}

// MARK: - Opportunities

private extension EarnSearchViewModel {
    func apply(_ state: FeedSearchProviderState<EarnTokenModel>) {
        guard query.isNotEmpty else {
            return
        }

        switch state {
        case .loading:
            if case .results = opportunities {
                return
            }

            opportunities = .loading

        case .loaded(let tokens):
            opportunities = .results(tokens.map(makeItemViewModel(for:)))

        case .empty:
            opportunities = .empty

        case .failed:
            opportunities = .failed
        }
    }

    func makeItemViewModel(for token: EarnTokenModel) -> EarnTokenItemViewModel {
        EarnTokenItemViewModel(token: token) { [weak self] in
            self?.onSelect(token)
        }
    }

    func onSelect(_ token: EarnTokenModel) {
        analyticsProvider.logOpportunitySelected(
            token: token.symbol,
            blockchain: token.networkName,
            source: Constants.source.rawValue
        )

        let resolution = resolver.resolve(earnToken: token, userWalletModels: userWalletModels)
        router.routeOnTokenResolved(resolution, source: Constants.source)
    }
}

// MARK: - Types

extension EarnSearchViewModel {
    enum OpportunitiesState {
        case loading
        case results([EarnTokenItemViewModel])
        case empty
        case failed
    }
}

// MARK: - Constants

private extension EarnSearchViewModel {
    enum Constants {
        static let searchDebounce: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500)
        static let source: EarnOpportunitySource = .search
    }
}
