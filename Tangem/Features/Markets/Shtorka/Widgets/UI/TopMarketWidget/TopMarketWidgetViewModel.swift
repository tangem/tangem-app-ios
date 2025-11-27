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
                case .loading, .failedToFetchData:
                    if case .failedToFetchData = oldEvent { return }
                    viewModel.tokenListLoadingState = .loading
                case .idle:
                    break
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
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { viewModel, event in
                guard case .appendedItems(let items, _) = event else {
                    return
                }

                let idsToFetchMiniCharts = items.map { $0.id }

                viewModel.chartsHistoryProvider.fetch(
                    for: idsToFetchMiniCharts,
                    with: viewModel.filterProvider.currentFilterValue.interval
                )

                viewModel.quotesRepositoryUpdateHelper.updateQuotes(
                    marketsTokens: items,
                    for: AppSettings.shared.selectedCurrencyCode
                )
            })
            .compactMap { viewModel, event in
                guard case .appendedItems(let items, _) = event else {
                    return nil
                }

                let tokenViewModelsToAppend = viewModel.mapToItemViewModel(items, offset: viewModel.tokenViewModels.count)
                return tokenViewModelsToAppend
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { (viewModel: PulseMarketWidgetViewModel, items: [MarketTokenItemViewModel]) in
                viewModel.tokenViewModels.append(contentsOf: items)
                viewModel.tokenListLoadingState = .loaded
            }
            .store(in: &bag)
    }

    func mapToItemViewModel(_ list: [MarketsTokenModel], offset: Int) -> [TopMarketTokenViewModel] {
        list.prefix(Constants.itemsOnListWidget).enumerated().map { mapToTokenViewModel(index: $0 + offset, tokenItemModel: $1) }
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

private extension TopMarketWidgetViewModel {
    enum Constants {
        static let itemsOnListWidget = 5
    }
}
