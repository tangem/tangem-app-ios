//
//  RelatedTokensViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

@MainActor
final class RelatedTokensViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var tokenViewModels: [MarketTokenItemViewModel] = []
    @Published private(set) var loadingState: LoadingState = .idle

    // MARK: - Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Private Properties

    private let tokens: [NewsDetailsViewModel.RelatedToken]
    private let newsId: Int
    private let filterProvider = MarketsListDataFilterProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private var marketCapFormatter: MarketCapFormatter
    private weak var coordinator: NewsDetailsRoutable?

    // MARK: - Init

    init(tokens: [NewsDetailsViewModel.RelatedToken], newsId: Int, coordinator: NewsDetailsRoutable?) {
        self.tokens = tokens
        self.newsId = newsId
        self.coordinator = coordinator
        marketCapFormatter = MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )
    }

    // MARK: - Public Methods

    func loadIfNeeded() {
        guard loadingState == .idle, !tokens.isEmpty else { return }
        load()
    }

    func retry() {
        load()
    }

    // MARK: - Private Methods

    private func load() {
        loadingState = .loading

        runTask(in: self) { viewModel in
            do {
                let marketsTokens = try await viewModel.fetchTokensData()
                viewModel.processTokens(marketsTokens)
            } catch {
                viewModel.loadingState = .error
            }
        }
    }

    private func fetchTokensData() async throws -> [MarketsTokenModel] {
        let currencyCode = AppSettings.shared.selectedCurrencyCode
        let language = Locale.current.language.languageCode?.identifier ?? "en"

        // Fetch each token's details to get full data including marketCap
        let marketsTokens: [MarketsTokenModel] = await withTaskGroup(of: MarketsTokenModel?.self) { group in
            for token in tokens {
                group.addTask { [tangemApiService] in
                    do {
                        let request = MarketsDTO.Coins.Request(
                            tokenId: token.id,
                            currency: currencyCode,
                            language: language
                        )
                        let response = try await tangemApiService.loadTokenMarketsDetails(requestModel: request)

                        return MarketsTokenModel(
                            id: response.id,
                            name: response.name,
                            symbol: response.symbol,
                            currentPrice: response.currentPrice,
                            priceChangePercentage: response.priceChangePercentage,
                            marketRating: response.metrics?.marketRating,
                            maxYieldApy: nil,
                            marketCap: response.metrics?.marketCap,
                            isUnderMarketCapLimit: nil,
                            stakingOpportunities: nil
                        )
                    } catch {
                        return nil
                    }
                }
            }

            var results: [MarketsTokenModel] = []
            for await result in group {
                if let token = result {
                    results.append(token)
                }
            }
            return results
        }

        return marketsTokens
    }

    private func processTokens(_ marketsTokens: [MarketsTokenModel]) {
        let tokenIds = marketsTokens.map(\.id)
        chartsHistoryProvider.fetch(for: tokenIds, with: filterProvider.currentFilterValue.interval)

        let viewModels = marketsTokens.map { tokenModel in
            MarketTokenItemViewModel(
                tokenModel: tokenModel,
                marketCapFormatter: marketCapFormatter,
                chartsProvider: chartsHistoryProvider,
                filterProvider: filterProvider,
                onTapAction: { [weak self] in
                    self?.openTokenDetails(tokenModel)
                }
            )
        }

        tokenViewModels = viewModels
        loadingState = viewModels.isEmpty ? .error : .loaded
    }

    private func openTokenDetails(_ tokenModel: MarketsTokenModel) {
        Analytics.log(
            event: .marketsChartScreenOpened,
            params: [
                .token: tokenModel.symbol,
                .source: Analytics.ParameterValue.newsSourceNewsPage.rawValue,
                .newsId: String(newsId),
            ]
        )
        coordinator?.openTokenDetails(tokenModel)
    }
}

// MARK: - LoadingState

extension RelatedTokensViewModel {
    enum LoadingState {
        case idle
        case loading
        case loaded
        case error
    }
}
