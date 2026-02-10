//
//  PulseMarketWidgetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import TangemFoundation

final class PulseMarketWidgetViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Published var filterSelectedId: String? = nil
    @Published private(set) var isFirstLoading: Bool = true
    @Published private(set) var tokenViewModelsState: LoadingResult<[MarketTokenItemViewModel], Error> = .loading

    var isNeedDisplayFilter: Bool {
        !isFirstLoading
    }

    var availabilityToSelectionOrderType: [MarketsListOrderType] {
        let allowed = MarketsListOrderType.allCases.filter {
            switch $0 {
            case .rating, .staking, .yield:
                return false
            default:
                return true
            }
        }

        // Required UI order: Trending -> Top Gainers -> Top Losers -> Experienced buyers
        let ordered: [MarketsListOrderType] = [.trending, .gainers, .losers, .buyers]
        return ordered.filter { allowed.contains($0) }
    }

    // MARK: - Properties

    let widgetType: MarketsWidgetType
    private weak var coordinator: PulseMarketWidgetRoutable?

    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
    private let widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler
    private let analyticsService: PulseMarketWidgetAnalyticsProvider

    private let filterProvider = MarketsListDataFilterProvider(initialOrderType: Constants.initialOrderType)
    private let dataProvider = MarketsListDataProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private let quotesUpdatesScheduler = MarketsQuotesUpdatesScheduler()

    private var marketCapFormatter: MarketCapFormatter
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        widgetType: MarketsWidgetType,
        widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler,
        quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper,
        analyticsService: PulseMarketWidgetAnalyticsProvider,
        coordinator: PulseMarketWidgetRoutable?
    ) {
        self.widgetType = widgetType
        self.widgetsUpdateHandler = widgetsUpdateHandler
        self.quotesRepositoryUpdateHelper = quotesRepositoryUpdateHelper
        self.analyticsService = analyticsService
        self.coordinator = coordinator

        marketCapFormatter = .init(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )

        bindToCurrencyCodeUpdate()
        dataProviderBind()
        bindToOrderUpdate()

        // Need for preload markets list, when bottom sheet it has not been opened yet
        quotesUpdatesScheduler.saveQuotesUpdateDate(Date())
        fetch(by: filterProvider.currentFilterValue)
    }

    deinit {
        AppLogger.debug("PulseMarketWidgetViewModel deinit")
    }

    // MARK: - Public Implementation

    func tryLoadAgain() {
        dataProvider.reset()
        fetch(by: filterProvider.currentFilterValue)
    }

    func onSeeAllTapAction() {
        let currentFilter = filterProvider.currentFilterValue

        analyticsService.logPulseMarketTokenListOpened()
        analyticsService.logTokensSort(
            type: currentFilter.order.analyticsValue.capitalizingFirstLetter(),
            period: currentFilter.interval.rawValue
        )

        runTask(in: self) { @MainActor viewModel in
            viewModel.coordinator?.openSeeAllPulseMarketWidget(with: viewModel.filterProvider.currentFilterValue.order)
        }
    }
}

// MARK: - Private Implementation

private extension PulseMarketWidgetViewModel {
    func fetch(by filter: MarketsListDataProvider.Filter) {
        dataProvider.fetch("", with: filter)
    }

    func bindToCurrencyCodeUpdate() {
        AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, newCurrencyCode in
                viewModel.marketCapFormatter = .init(divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList, baseCurrencyCode: newCurrencyCode, notationFormatter: .init())
                viewModel.dataProvider.reset()
                viewModel.fetch(by: viewModel.filterProvider.currentFilterValue)
            }
            .store(in: &bag)
    }

    func bindToOrderUpdate() {
        // Map selected chip id to MarketsListOrderType and update provider
        $filterSelectedId
            .dropFirst()
            .removeDuplicates()
            // Wait a few milliseconds for smoother performance
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .compactMap { [weak self] id -> MarketsListOrderType? in
                guard let self, let id else { return nil }
                return availabilityToSelectionOrderType.first(where: { $0.rawValue == id })
            }
            .withWeakCaptureOf(self)
            .sink { viewModel, order in
                guard viewModel.filterProvider.currentFilterValue.order != order else {
                    return
                }

                viewModel.filterProvider.didSelectMarketOrder(order)
            }
            .store(in: &bag)

        // React to filter changes and update data with current logic
        filterProvider.filterPublisher
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, newFilter in
                let previousOrder = viewModel.dataProvider.lastFilterValue?.order
                if previousOrder != newFilter.order {
                    viewModel.dataProvider.reset()
                    viewModel.fetch(by: viewModel.filterProvider.currentFilterValue)
                }
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
                case .loading:
                    if case .failedToFetchData = oldEvent { return }
                    viewModel.widgetsUpdateHandler.performUpdateLoading(state: .loading, for: viewModel.widgetType)
                case .idle:
                    break
                case .failedToFetchData:
                    if viewModel.dataProvider.items.isEmpty {
                        viewModel.quotesUpdatesScheduler.cancelUpdates()
                    }

                    viewModel.widgetsUpdateHandler.performUpdateLoading(state: .error, for: viewModel.widgetType)
                case .startInitialFetch, .cleared:
                    viewModel.widgetsUpdateHandler.performUpdateLoading(state: .loading, for: viewModel.widgetType)
                    viewModel.quotesUpdatesScheduler.saveQuotesUpdateDate(Date())

                    viewModel.quotesUpdatesScheduler.resetUpdates()
                default:
                    break
                }
            }
            .store(in: &bag)

        dataProviderEventPipeline
            .receiveOnMain()
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
            .receiveOnMain()
            .sink { viewModel, _ in
                viewModel.widgetsUpdateHandler.performUpdateLoading(state: .loaded, for: viewModel.widgetType)
            }
            .store(in: &bag)

        widgetsUpdateHandler
            .widgetsUpdateStateEventPublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                switch state {
                case .loaded:
                    viewModel.mapReadyForDisplay()
                    viewModel.clearIsFirstLoadingFlag()
                case .initialLoading:
                    viewModel.tokenViewModelsState = .loading
                case .reloading(let widgetTypes):
                    if widgetTypes.contains(viewModel.widgetType) {
                        viewModel.tokenViewModelsState = .loading
                    }
                case .allFailed:
                    return
                }
            }
            .store(in: &bag)
    }

    func mapToItemViewModel(_ list: [MarketsTokenModel], offset: Int) -> [MarketTokenItemViewModel] {
        list.enumerated().map { mapToTokenViewModel(index: $0 + offset, tokenItemModel: $1) }
    }

    func mapToTokenViewModel(index: Int, tokenItemModel: MarketsTokenModel) -> MarketTokenItemViewModel {
        MarketTokenItemViewModel(
            tokenModel: tokenItemModel,
            marketCapFormatter: marketCapFormatter,
            chartsProvider: chartsHistoryProvider,
            filterProvider: filterProvider,
            onTapAction: { [weak self] in
                self?.onTokenTapAction(with: tokenItemModel)
            }
        )
    }

    // MARK: - Map Widget States

    func mapReadyForDisplay() {
        switch dataProvider.lastEvent {
        case .appendedItems:
            let items = dataProvider.items.prefix(Constants.itemsOnListWidget)
            let tokenViewModelsToAppend = mapToItemViewModel(Array(items), offset: 0)
            tokenViewModelsState = .success(tokenViewModelsToAppend)
        case .failedToFetchData(let error):
            tokenViewModelsState = .failure(error)
            analyticsService.logPulseMarketLoadError(error)
        case .loading, .startInitialFetch, .cleared:
            tokenViewModelsState = .loading
        case .idle:
            break
        }
    }

    // MARK: - Actions

    private func onTokenTapAction(with tokenItemModel: MarketsTokenModel) {
        runTask(in: self) { @MainActor viewModel in
            viewModel.coordinator?.openMarketsTokenDetails(for: tokenItemModel)
        }
    }

    private func clearIsFirstLoadingFlag() {
        // Remove duplicate publishing property
        if isFirstLoading {
            isFirstLoading = false
        }
    }
}

private extension PulseMarketWidgetViewModel {
    enum Constants {
        static let initialOrderType: MarketsListOrderType = .trending
        static let itemsOnListWidget = 5
    }
}
