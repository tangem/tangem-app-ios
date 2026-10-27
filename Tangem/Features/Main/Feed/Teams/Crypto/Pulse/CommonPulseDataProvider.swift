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

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        isLoadingSubject.eraseToAnyPublisher()
    }

    private let tokensSubject = CurrentValueSubject<[MarketsTokenModel], Never>([])
    private let failedSubject = CurrentValueSubject<Bool, Never>(false)
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(true)

    private let listProvider = MarketsListDataProvider()
    private let filterProvider = MarketsListDataFilterProvider(analyticsSection: .crypto)
    private lazy var rowsProvider = MarketTokenRowsProvider(filterProvider: filterProvider)

    /// `MarketsListDataProvider` publishes `$items` from its fetch task, so the flag is read there and written from the caller's thread.
    private let isReloading = OSAllocatedUnfairLock(initialState: false)
    private var bag = Set<AnyCancellable>()

    init() {
        bind()
    }

    func makeRowViewModel(for token: MarketsTokenModel, onTap: @escaping () -> Void) -> MarketTokenItemViewModel {
        rowsProvider.makeRowViewModel(for: token, onTap: onTap)
    }

    func load(interval: PulseInterval, category: PulseCategory, tag: PulseTagSelection?, isCategoryUserInitiated: Bool) {
        filterProvider.didSelectMarketPriceInterval(interval.marketsInterval)
        filterProvider.didSelectMarketOrder(category.marketsOrder, isUserInitiated: isCategoryUserInitiated)
        filterProvider.didSelectCategory(tag.map { .init(geckoCategoryId: $0.id, country: $0.country) })
        reload()
    }

    func loadMore() {
        guard listProvider.canFetchMore else {
            return
        }

        listProvider.fetchMore()
    }

    func setVisibleTokenIDs(_ ids: Set<String>) {
        rowsProvider.setVisibleTokenIDs(ids)
    }

    func suspendQuotes() {
        rowsProvider.suspendQuotes()
    }

    func resumeQuotes() {
        rowsProvider.resumeQuotes()
    }

    private func reload() {
        isReloading.withLock { $0 = true }

        // Loading and the cleared failure go first: clearing the tokens on their own is a state that renders
        // the no-results text, and on a retry the stale failure would outlive the tap.
        isLoadingSubject.send(true)
        failedSubject.send(false)
        tokensSubject.send([])

        listProvider.reset()
        listProvider.fetch(.empty, with: filterProvider.currentFilterValue)
        rowsProvider.requestCharts()
    }

    /// The `$items` sink swallows the empty list `reset()` produces while a reload is in flight, so when the
    /// reload ends without a page (empty result or failure) the previous filter's list has to be cleared from here.
    private func finishReloadWithoutItems() {
        let wasReloading = isReloading.withLock { reloading -> Bool in
            defer { reloading = false }
            return reloading
        }

        guard wasReloading else { return }

        tokensSubject.send([])
    }

    private func bind() {
        listProvider
            .$items
            .withWeakCaptureOf(self)
            .sink { provider, items in
                let swallowsReset = provider.isReloading.withLock { reloading -> Bool in
                    guard items.isEmpty, reloading else {
                        reloading = false
                        return false
                    }

                    return true
                }

                guard !swallowsReset else {
                    return
                }

                provider.rowsProvider.updateQuotes(for: items)
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
                    provider.isLoadingSubject.send(false)
                    provider.finishReloadWithoutItems()
                case .appendedItems:
                    provider.failedSubject.send(false)
                    provider.isLoadingSubject.send(false)

                    if provider.listProvider.items.isEmpty {
                        provider.finishReloadWithoutItems()
                    }
                case .startInitialFetch:
                    provider.failedSubject.send(false)
                    provider.isLoadingSubject.send(true)
                case .loading, .idle, .cleared:
                    // `.loading` also precedes a `fetch()` that bails out on an already scheduled retry,
                    // so it must not clear the failure or the retry cycle would flicker the error state.
                    break
                }
            }
            .store(in: &bag)

        rowsProvider
            .currencyDidChangePublisher
            .withWeakCaptureOf(self)
            .sink { provider, _ in
                provider.reload()
            }
            .store(in: &bag)
    }
}

// MARK: - Markets mapping

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
