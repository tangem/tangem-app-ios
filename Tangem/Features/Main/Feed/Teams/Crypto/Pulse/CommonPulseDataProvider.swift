//
//  CommonPulseDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class CommonPulseDataProvider: PulseDataProvider {
    var tokensPublisher: AnyPublisher<[MarketsTokenModel], Never> {
        tokensSubject.eraseToAnyPublisher()
    }

    var failedPublisher: AnyPublisher<Bool, Never> {
        failedSubject.eraseToAnyPublisher()
    }

    var canLoadMore: Bool {
        listProvider.canFetchMore
    }

    private let tokensSubject = CurrentValueSubject<[MarketsTokenModel], Never>([])
    private let failedSubject = CurrentValueSubject<Bool, Never>(false)
    private let chartsRequestSubject = PassthroughSubject<Void, Never>()

    private let listProvider = MarketsListDataProvider()
    private let filterProvider = MarketsListDataFilterProvider()
    private let chartsProvider = MarketsListChartsHistoryProvider()
    private let quotesScheduler = MarketsQuotesUpdatesScheduler()
    private let quotesUpdateHelper: MarketsQuotesUpdateHelper = CommonMarketsQuotesUpdateHelper()

    private var marketCapFormatter = MarketCapFormatter(
        divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
        baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
        notationFormatter: DefaultAmountNotationFormatter()
    )

    private var visibleTokenIDs: Set<String> = []
    private var isReloading = false
    private var bag = Set<AnyCancellable>()

    init() {
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

    func load(interval: PulseInterval, category: PulseCategory) {
        filterProvider.didSelectMarketPriceInterval(interval.marketsInterval)
        filterProvider.didSelectMarketOrder(category.marketsOrder)
        reload()
    }

    func loadMore() {
        guard listProvider.canFetchMore else {
            return
        }

        listProvider.fetchMore()
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

    func suspendQuotes() {
        quotesScheduler.cancelUpdates()
    }

    func resumeQuotes() {
        quotesScheduler.resumeUpdates()
    }

    private func reload() {
        isReloading = true
        listProvider.reset()
        listProvider.fetch(.empty, with: filterProvider.currentFilterValue)
        chartsRequestSubject.send()
    }

    private func bind() {
        listProvider
            .$items
            .withWeakCaptureOf(self)
            .sink { provider, items in
                guard !items.isEmpty || !provider.isReloading else {
                    return
                }

                provider.isReloading = false
                provider.quotesUpdateHelper.updateQuotes(
                    marketsTokens: items,
                    for: AppSettings.shared.selectedCurrencyCode
                )
                provider.tokensSubject.send(items)
            }
            .store(in: &bag)

        listProvider
            .$lastEvent
            .withWeakCaptureOf(self)
            .sink { provider, event in
                switch event {
                case .failedToFetchData:
                    provider.failedSubject.send(true)
                case .appendedItems, .startInitialFetch:
                    provider.failedSubject.send(false)
                case .loading, .idle, .cleared:
                    break
                }
            }
            .store(in: &bag)

        AppSettings.shared
            .$selectedCurrencyCode
            .dropFirst()
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, currencyCode in
                provider.marketCapFormatter = MarketCapFormatter(
                    divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
                    baseCurrencyCode: currencyCode,
                    notationFormatter: DefaultAmountNotationFormatter()
                )
                provider.reload()
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

private extension CommonPulseDataProvider {
    enum Constants {
        static let chartsRequestDebounce: DispatchQueue.SchedulerTimeType.Stride = 0.3
    }
}

private extension PulseInterval {
    var marketsInterval: MarketsPriceIntervalType {
        switch self {
        case .day: .day
        case .week: .week
        case .month: .month
        }
    }
}

private extension PulseCategory {
    var marketsOrder: MarketsListOrderType {
        switch self {
        case .marketCap: .rating
        case .topGainers: .gainers
        case .topLosers: .losers
        case .experiencedBuyers: .buyers
        case .trending: .trending
        }
    }
}
