//
//  MarketTokenRowsProvider.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

/// Charts, quotes and market cap formatting shared by the feed lists built from `MarketTokenItemViewModel`.
final class MarketTokenRowsProvider {
    /// A row formats its market cap once, so the owner has to rebuild its rows when the currency changes.
    var currencyDidChangePublisher: AnyPublisher<Void, Never> {
        currencyDidChangeSubject.eraseToAnyPublisher()
    }

    private let filterProvider: MarketsListDataFilterProvider
    private let chartsProvider = MarketsListChartsHistoryProvider()
    private let quotesScheduler = MarketsQuotesUpdatesScheduler()
    private let quotesUpdateHelper: MarketsQuotesUpdateHelper = CommonMarketsQuotesUpdateHelper()
    private let chartsRequestSubject = PassthroughSubject<Void, Never>()
    private let currencyDidChangeSubject = PassthroughSubject<Void, Never>()

    private var marketCapFormatter = MarketTokenRowsProvider.makeMarketCapFormatter(currencyCode: AppSettings.shared.selectedCurrencyCode)
    private var visibleTokenIDs: Set<String> = []
    private var bag = Set<AnyCancellable>()

    init(filterProvider: MarketsListDataFilterProvider) {
        self.filterProvider = filterProvider

        bind()
    }

    func makeRowViewModel(for token: MarketsTokenModel, onTap: @escaping () -> Void) -> MarketTokenItemViewModel {
        MarketTokenItemViewModel(
            tokenModel: token,
            marketCapFormatter: marketCapFormatter,
            chartsProvider: chartsProvider,
            filterProvider: filterProvider,
            onTapAction: onTap
        )
    }

    func updateQuotes(for tokens: [MarketsTokenModel]) {
        quotesUpdateHelper.updateQuotes(marketsTokens: tokens, for: AppSettings.shared.selectedCurrencyCode)
    }

    func setVisibleTokenIDs(_ ids: Set<String>) {
        let hidden = visibleTokenIDs.subtracting(ids)

        if hidden.isNotEmpty {
            quotesScheduler.stopUpdatingQuotes(for: hidden)
        }

        visibleTokenIDs = ids
        quotesScheduler.scheduleQuotesUpdate(for: ids)
        chartsRequestSubject.send()
    }

    func requestCharts() {
        chartsRequestSubject.send()
    }

    func suspendQuotes() {
        quotesScheduler.cancelUpdates()
    }

    func resumeQuotes() {
        quotesScheduler.resumeUpdates()
    }
}

// MARK: - Private implementation

private extension MarketTokenRowsProvider {
    static func makeMarketCapFormatter(currencyCode: String) -> MarketCapFormatter {
        MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: currencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )
    }

    func bind() {
        AppSettings.shared
            .$selectedCurrencyCode
            .dropFirst()
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, currencyCode in
                provider.marketCapFormatter = Self.makeMarketCapFormatter(currencyCode: currencyCode)

                // The cache has to be gone before the owner asks for its list again, or the refetch is filtered out.
                Task { @MainActor in
                    provider.chartsProvider.reset()
                    provider.currencyDidChangeSubject.send()
                }
            }
            .store(in: &bag)

        chartsRequestSubject
            .debounce(for: Constants.chartsRequestDebounce, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { provider, _ in
                provider.chartsProvider.fetch(
                    for: Array(provider.visibleTokenIDs),
                    with: provider.filterProvider.currentFilterValue.interval
                )
            }
            .store(in: &bag)
    }
}

// MARK: - Constants

private extension MarketTokenRowsProvider {
    enum Constants {
        static let chartsRequestDebounce: DispatchQueue.SchedulerTimeType.Stride = 0.3
    }
}
