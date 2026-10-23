//
//  FeedSearchPortfolioProvider.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class FeedSearchPortfolioProvider {
    var portfolioPublisher: AnyPublisher<MarketsPortfolioTokenListViewModel?, Never> {
        portfolioSubject.eraseToAnyPublisher()
    }

    private let walletModelsAggregator: WalletModelsAggregator
    private let matcher = FeedSearchPortfolioMatcher()
    private let onSelect: (any WalletModel) -> Void
    private let portfolioSubject = CurrentValueSubject<MarketsPortfolioTokenListViewModel?, Never>(nil)

    private var bag = Set<AnyCancellable>()

    init(
        query: AnyPublisher<String, Never>,
        walletModelsAggregator: WalletModelsAggregator = CommonWalletModelsAggregator(),
        onSelect: @escaping (any WalletModel) -> Void
    ) {
        self.walletModelsAggregator = walletModelsAggregator
        self.onSelect = onSelect

        bind(to: query)
    }
}

// MARK: - Binding

private extension FeedSearchPortfolioProvider {
    func bind(to query: AnyPublisher<String, Never>) {
        let trimmedQuery = query
            .map { $0.trimmed() }
            .removeDuplicates()

        Publishers.CombineLatest(trimmedQuery, walletModelsAggregator.walletModelsPublisher)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { provider, input in
                let (query, walletModels) = input
                return provider.makePortfolio(query: query, walletModels: walletModels)
            }
            .subscribe(portfolioSubject)
            .store(in: &bag)
    }
}

// MARK: - Private

private extension FeedSearchPortfolioProvider {
    func makePortfolio(query: String, walletModels: [any WalletModel]) -> MarketsPortfolioTokenListViewModel? {
        let matches = matcher.matches(query: query, walletModels: walletModels)

        guard matches.isNotEmpty else {
            return nil
        }

        let viewModel = MarketsPortfolioTokenListViewModel(
            walletModels: matches,
            dismissesOnSelect: false,
            onSelect: onSelect
        )

        return viewModel.sections.isEmpty ? nil : viewModel
    }
}
