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
    @Published private(set) var tokenViewModelsState: LoadingResult<[MarketTokenItemViewModel], Error> = .loading

    // MARK: - Properties

    let widgetType: MarketsWidgetType
    private weak var coordinator: TopMarketWidgetRoutable?

    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
    private let widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler

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
        coordinator: TopMarketWidgetRoutable?
    ) {
        self.widgetType = widgetType
        self.widgetsUpdateHandler = widgetsUpdateHandler
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
        fetch(by: filterProvider.currentFilterValue)
    }

    deinit {
        AppLogger.debug("TopMarketWidgetViewModel deinit")
    }

    // MARK: - Public Implementation

    func tryLoadAgain() {
        isFirstLoading = true
        tokenViewModelsState = .loading
        dataProvider.reset()
        fetch(by: filterProvider.currentFilterValue)
    }

    func onSeeAllTapAction() {
        Analytics.log(
            event: .marketsTokenListOpened,
            params: [
                .source: Analytics.ParameterValue.markets.rawValue,
            ]
        )

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
                    viewModel.tokenViewModelsState = .loading
                    viewModel.widgetsUpdateHandler.performUpdateLoading(state: .loading, for: viewModel.widgetType)
                case .idle:
                    break
                case .failedToFetchData(let error):
                    if viewModel.dataProvider.items.isEmpty {
                        viewModel.quotesUpdatesScheduler.cancelUpdates()

                        let analyticsParams = error.marketsAnalyticsParams
                        Analytics.log(
                            event: .marketsMarketsLoadError,
                            params: [
                                .errorCode: analyticsParams[.errorCode] ?? "",
                                .errorMessage: analyticsParams[.errorMessage] ?? "",
                            ]
                        )
                    }

                    viewModel.tokenViewModelsState = .failure(error)
                    viewModel.widgetsUpdateHandler.performUpdateLoading(state: .error, for: viewModel.widgetType)
                case .startInitialFetch, .cleared:
                    viewModel.tokenViewModelsState = .loading
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
                if case .readyForDisplay = state, viewModel.dataProvider.lastEvent.isAppendedItems {
                    let items = viewModel.dataProvider.items.prefix(Constants.itemsOnListWidget)
                    let tokenViewModelsToAppend = viewModel.mapToItemViewModel(Array(items), offset: 0)
                    viewModel.tokenViewModelsState = .success(tokenViewModelsToAppend)
                }

                viewModel.clearIsFirstLoadingFlag()
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

private extension TopMarketWidgetViewModel {
    enum Constants {
        static let itemsOnListWidget = 5
    }
}
