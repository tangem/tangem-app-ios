//
//  TopMarketWidgetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import Kingfisher

typealias TopMarketTokenViewModel = MarketTokenItemViewModel

final class TopMarketWidgetViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Published private(set) var tokenViewModels: [TopMarketTokenViewModel] = []
    @Published private(set) var tokenListLoadingState: TopMarketWidgetView.ListLoadingState = .idle

    // MARK: - Properties

    private weak var coordinator: TopMarketWidgetRoutable?

    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
    private let filterProvider = MarketsListDataFilterProvider()
    private let dataProvider = MarketsListDataProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private let quotesUpdatesScheduler = MarketsQuotesUpdatesScheduler()
    private let imageCache = KingfisherManager.shared.cache

    private var marketCapFormatter: MarketCapFormatter
    private var bag = Set<AnyCancellable>()
    private var currentSearchValue: String = ""
    private var isViewVisible: Bool = false

    // MARK: - Init

    init(
        quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper,
        coordinator: TopMarketWidgetRoutable?
    ) {
        self.quotesRepositoryUpdateHelper = quotesRepositoryUpdateHelper
        self.coordinator = coordinator

        marketCapFormatter = .init(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )

        bindToCurrencyCodeUpdate()
        dataProviderBind()

        // Need for preload markets list, when bottom sheet it has not been opened yet
        quotesUpdatesScheduler.saveQuotesUpdateDate(Date())
        fetch(with: "", by: filterProvider.currentFilterValue)
    }

    deinit {
        AppLogger.debug("TopMarketWidgetViewModel deinit")
    }

    /// Handles `SwiftUI.View.onAppear(perform:)`.
    func onViewAppear() {
        isViewVisible = true
    }

    /// Handles `SwiftUI.View.onDisappear(perform:)`.
    func onViewDisappear() {
        isViewVisible = false
    }

    func onTryLoadList() {
        tokenListLoadingState = .loading
        fetch(with: currentSearchValue, by: filterProvider.currentFilterValue)
    }

    func closeStakingNotification() {
        Analytics.log(.marketsStakingPromoClosed)
        AppSettings.shared.startWalletUsageDate = .distantFuture
    }
}

// MARK: - Private Implementation

private extension TopMarketWidgetViewModel {
    func fetch(with searchText: String = "", by filter: MarketsListDataProvider.Filter) {
        dataProvider.fetch(searchText, with: filter)
    }

    func bindToCurrencyCodeUpdate() {
        AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, newCurrencyCode in
                viewModel.marketCapFormatter = .init(divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList, baseCurrencyCode: newCurrencyCode, notationFormatter: .init())
                viewModel.dataProvider.reset()
                viewModel.fetch(with: viewModel.currentSearchValue, by: viewModel.filterProvider.currentFilterValue)
            }
            .store(in: &bag)
    }

    func requestMiniCharts(forRange range: ClosedRange<Int>, interval: MarketsPriceIntervalType) {
        let items = tokenViewModels
        let itemsToFetch: Array<TopMarketTokenViewModel>.SubSequence
        if items.isEmpty || items.count <= range.lowerBound {
            // If items array was cleared or previous visible range was sent we can skip mini-charts loading step
            return
        }

        if items.count <= range.upperBound {
            itemsToFetch = items[range.lowerBound...]
        } else {
            itemsToFetch = items[range]
        }
        let idsToFetch = Array(itemsToFetch).map { $0.tokenId }
        chartsHistoryProvider.fetch(for: idsToFetch, with: interval)
    }

    func dataProviderBind() {
        let dataProviderEventPipeline = dataProvider.$lastEvent
            .removeDuplicates()
            .share(replay: 1)

        dataProviderEventPipeline
            .receive(on: DispatchQueue.main)
            .withPrevious()
            .withWeakCaptureOf(self)
            .sink { viewModel, events in
                let (oldEvent, newEvent) = events
                switch newEvent {
                case .loading:
                    if case .failedToFetchData = oldEvent { return }
                    viewModel.tokenListLoadingState = .loading
                case .idle:
                    break
                case .failedToFetchData:
                    if viewModel.dataProvider.items.isEmpty {
                        viewModel.quotesUpdatesScheduler.cancelUpdates()
                    }

                    viewModel.tokenListLoadingState = .loading
                case .startInitialFetch, .cleared:
                    viewModel.tokenListLoadingState = .loading
                    viewModel.tokenViewModels.removeAll()
                    viewModel.quotesUpdatesScheduler.saveQuotesUpdateDate(Date())

                    viewModel.quotesUpdatesScheduler.resetUpdates()
                default:
                    break
                }
            }
            .store(in: &bag)

        dataProviderEventPipeline
            .filter { $0.isAppendedItems }
            .handleEvents(receiveOutput: { [weak self] event in
                guard
                    let self,
                    case .appendedItems(let items, _) = event
                else {
                    return
                }

                let idsToFetchMiniCharts = items.map { $0.id }
                chartsHistoryProvider.fetch(
                    for: idsToFetchMiniCharts,
                    with: filterProvider.currentFilterValue.interval
                )

                quotesRepositoryUpdateHelper.updateQuotes(marketsTokens: items, for: AppSettings.shared.selectedCurrencyCode)
            })
            .withWeakCaptureOf(self)
            .compactMap { viewModel, event in
                guard case .appendedItems(let items, _) = event else {
                    return nil
                }

                let tokenViewModelsToAppend = viewModel.mapToItemViewModel(items, offset: viewModel.tokenViewModels.count)
                return tokenViewModelsToAppend
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { (viewModel: TopMarketWidgetViewModel, items: [TopMarketTokenViewModel]) in
                viewModel.tokenViewModels.append(contentsOf: items)

                if viewModel.dataProvider.items.count < Constants.itemsOnListWidget {
                    viewModel.tokenListLoadingState = .loading
                    return
                }

                viewModel.tokenListLoadingState = .idle
            }
            .store(in: &bag)
    }

    func mapToItemViewModel(_ list: [MarketsTokenModel], offset: Int) -> [TopMarketTokenViewModel] {
        guard list.count >= Constants.itemsOnListWidget else {
            return []
        }

        return list.prefix(Constants.itemsOnListWidget).enumerated().map { mapToTokenViewModel(index: $0 + offset, tokenItemModel: $1) }
    }

    func mapToTokenViewModel(index: Int, tokenItemModel: MarketsTokenModel) -> TopMarketTokenViewModel {
        TopMarketTokenViewModel(
            tokenModel: tokenItemModel,
            marketCapFormatter: marketCapFormatter,
            chartsProvider: chartsHistoryProvider,
            filterProvider: filterProvider,
            onTapAction: { [weak self] in
                self?.coordinator?.openMarketsTokenDetails(for: tokenItemModel)
            }
        )
    }

    func onAppearPrepareImageCache() {
        imageCache.memoryStorage.config.countLimit = 250
    }
}

private extension MarketsListDataProvider.Event {
    var isAppendedItems: Bool {
        if case .appendedItems = self {
            return true
        }

        return false
    }
}

private extension TopMarketWidgetViewModel {
    enum Constants {
        static let itemsOnListWidget = 5
    }
}
