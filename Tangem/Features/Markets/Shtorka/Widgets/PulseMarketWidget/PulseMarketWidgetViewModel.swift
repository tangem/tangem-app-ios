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
    @Published private(set) var tokenViewModels: [MarketTokenItemViewModel] = []
    @Published private(set) var loadingState: WidgetLoadingState = .idle {
        didSet {
            widgetsUpdateHandler.performUpdateLoading(state: loadingState, for: widgetType)
        }
    }

    var availabilityToSelectionOrderType: [MarketsListOrderType] {
        MarketsListOrderType.allCases.filter {
            if case .rating = $0 {
                return false
            }

            return true
        }
    }

    // MARK: - Properties

    let widgetType: MarketsWidgetType
    private weak var coordinator: PulseMarketWidgetRoutable?

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
        coordinator: PulseMarketWidgetRoutable?
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
        bindToOrderUpdate()

        // Need for preload markets list, when bottom sheet it has not been opened yet
        quotesUpdatesScheduler.saveQuotesUpdateDate(Date())
    }

    deinit {
        AppLogger.debug("PulseMarketWidgetViewModel deinit")
    }

    // MARK: - Public Implementation

    func tryLoadAgain() {
        loadingState = .loading
        dataProvider.reset()
        fetch(by: filterProvider.currentFilterValue)
    }

    func onSeeAllTapAction() {
        runTask(in: self) { @MainActor viewModel in
            viewModel.coordinator?.openSeeAll(with: viewModel.widgetType)
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
            .receiveOnMain()
            .compactMap { [weak self] id -> MarketsListOrderType? in
                guard let self, let id else { return nil }
                return availabilityToSelectionOrderType.first(where: { $0.rawValue == id })
            }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, order in
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
                    viewModel.loadingState = .loading
                case .idle:
                    break
                case .failedToFetchData:
                    if viewModel.dataProvider.items.isEmpty {
                        viewModel.quotesUpdatesScheduler.cancelUpdates()
                    }

                    viewModel.loadingState = .error
                case .startInitialFetch, .cleared:
                    viewModel.loadingState = .loading
                    viewModel.tokenViewModels.removeAll()
                    viewModel.quotesUpdatesScheduler.saveQuotesUpdateDate(Date())

                    viewModel.quotesUpdatesScheduler.resetUpdates()
                default:
                    break
                }
            }
            .store(in: &bag)

        dataProviderEventPipeline
            .receive(on: DispatchQueue.main)
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
                viewModel.tokenViewModels.append(contentsOf: items.prefix(Constants.itemsOnListWidget))
                viewModel.loadingState = .loaded
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
}

private extension PulseMarketWidgetViewModel {
    enum Constants {
        static let itemsOnListWidget = 5
    }
}
