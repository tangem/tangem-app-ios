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
import TangemFoundation

final class TopMarketWidgetViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Published private(set) var isFirstLoading: Bool = true
    @Published private(set) var headerLoadingState: MarketsCommonWidgetHeaderView.LoadingState = .first
    @Published private(set) var tokenViewModelsState: LoadingResult<[MarketTokenItemViewModel], Error> = .loading

    // MARK: - Properties

    let widgetType: MarketsWidgetType
    private weak var coordinator: TopMarketWidgetRoutable?

    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
    private let widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler
    private let analyticsService: TopMarketWidgetAnalyticsProvider

    private let filterProvider = MarketsListDataFilterProvider()
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
        analyticsService: TopMarketWidgetAnalyticsProvider,
        coordinator: TopMarketWidgetRoutable?
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

        // Need for preload markets list, when bottom sheet it has not been opened yet
        quotesUpdatesScheduler.saveQuotesUpdateDate(Date())
        fetch(by: filterProvider.currentFilterValue)
    }

    deinit {
        AppLogger.debug("TopMarketWidgetViewModel deinit")
    }

    // MARK: - Public Implementation

    func tryLoadAgain() {
        dataProvider.reset()
        fetch(by: filterProvider.currentFilterValue)
    }

    func onSeeAllTapAction() {
        analyticsService.logTopMarketTokenListOpened()

        runTask(in: self) { @MainActor viewModel in
            viewModel.coordinator?.openSeeAllTopMarketWidget()
        }
    }
}

// MARK: - Private Implementation

private extension TopMarketWidgetViewModel {
    func fetch(by filter: MarketsListDataProvider.Filter) {
        dataProvider.fetch("", with: filter)
    }

    func bindToCurrencyCodeUpdate() {
        AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, newCurrencyCode in
                viewModel.marketCapFormatter = .init(divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList, baseCurrencyCode: newCurrencyCode, notationFormatter: .init())
                viewModel.dataProvider.reset()
                viewModel.fetch(by: viewModel.filterProvider.currentFilterValue)
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
                    viewModel.updateHeaderLoadingState()
                case .initialLoading:
                    viewModel.tokenViewModelsState = .loading
                    viewModel.updateHeaderLoadingState()
                case .reloading(let widgetTypes):
                    if widgetTypes.contains(viewModel.widgetType) {
                        viewModel.tokenViewModelsState = .loading
                        viewModel.updateHeaderLoadingState()
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
            analyticsService.logTopMarketLoadError(error)
        case .loading, .startInitialFetch, .cleared:
            tokenViewModelsState = .loading
        case .idle:
            break
        }
    }

    // MARK: - Actions

    func onTokenTapAction(with tokenItemModel: MarketsTokenModel) {
        analyticsService.logMarketsChartScreenOpened(tokenSymbol: tokenItemModel.symbol)

        runTask(in: self) { @MainActor viewModel in
            viewModel.coordinator?.openMarketsTokenDetails(for: tokenItemModel)
        }
    }

    func clearIsFirstLoadingFlag() {
        if isFirstLoading {
            isFirstLoading = false
        }
    }

    func updateHeaderLoadingState() {
        switch tokenViewModelsState {
        case .loading:
            headerLoadingState = isFirstLoading ? .first : .retry
        case .success:
            headerLoadingState = .loaded
        case .failure:
            headerLoadingState = .failed
        }
    }
}

private extension TopMarketWidgetViewModel {
    enum Constants {
        static let itemsOnListWidget = 5
    }
}
