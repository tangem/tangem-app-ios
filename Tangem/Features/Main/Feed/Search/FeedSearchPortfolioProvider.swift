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
    private let walletModelsAggregator: WalletModelsAggregator
    private let matcher = FeedSearchPortfolioMatcher()

    init(walletModelsAggregator: WalletModelsAggregator = CommonWalletModelsAggregator()) {
        self.walletModelsAggregator = walletModelsAggregator
    }

    func portfolioPublisher(
        query: some Publisher<String, Never>,
        isVisible: some Publisher<Bool, Never>,
        onSelect: @escaping (any WalletModel) -> Void
    ) -> AnyPublisher<MarketsPortfolioTokenListViewModel?, Never> {
        Publishers.CombineLatest3(query, isVisible, walletModelsAggregator.walletModelsPublisher)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { provider, input in
                let (query, isVisible, walletModels) = input
                return isVisible ? provider.makePortfolio(query: query, walletModels: walletModels, onSelect: onSelect) : nil
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension FeedSearchPortfolioProvider {
    func makePortfolio(
        query: String,
        walletModels: [any WalletModel],
        onSelect: @escaping (any WalletModel) -> Void
    ) -> MarketsPortfolioTokenListViewModel? {
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
