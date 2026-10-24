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
import TangemLocalization

final class PulseMarketWidgetViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Published var filterSelectedId: String? = nil
    @Published private(set) var searchText: String = ""
    @Published private(set) var isFirstLoading: Bool = true
    @Published private(set) var headerLoadingState: MarketsCommonWidgetHeaderLoadingState = .first
    @Published private(set) var tokenViewModelsState: LoadingResult<[MarketTokenItemViewModel], Error> = .loading

    var isSearchActive: Bool {
        searchText.trimmed().isNotEmpty
    }

    var headerTitle: String {
        isSearchActive ? Localization.marketsCommonTitle : (MarketsWidgetType.pulse.headerTitle ?? "")
    }

    var isNeedDisplayFilter: Bool {
        !isFirstLoading && !isSearchActive
    }

    var itemsOnListWidget: Int {
        Constants.itemsOnListWidget
    }

    var availabilityToSelectionOrderType: [MarketsListOrderType] {
        [.rating, .trending, .gainers, .losers, .buyers]
    }

    // MARK: - Properties

    private weak var coordinator: PulseMarketWidgetRoutable?

    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
    private let widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler
    private let analyticsService: PulseMarketWidgetAnalyticsProvider

    private let filterProvider: MarketsListDataFilterProvider
    private let dataProvider = MarketsListDataProvider(loadNetworks: true)
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private let quotesUpdatesScheduler = MarketsQuotesUpdatesScheduler()

    private var marketCapFormatter: MarketCapFormatter
    private var displayedTokenIDs: Set<String> = []
    private var bag = Set<AnyCancellable>()

    private let skeletonFloor = LoadingStateFloor()

    // MARK: - Init

    init(
        widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler,
        quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper,
        analyticsService: PulseMarketWidgetAnalyticsProvider,
        coordinator: PulseMarketWidgetRoutable?
    ) {
        self.widgetsUpdateHandler = widgetsUpdateHandler
        self.quotesRepositoryUpdateHelper = quotesRepositoryUpdateHelper
        self.analyticsService = analyticsService
        self.coordinator = coordinator

        filterProvider = MarketsListDataFilterProvider(
            initialOrderType: .rating
        )

        marketCapFormatter = .init(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )

        bindToCurrencyCodeUpdate()
        dataProviderBind()
        bindToOrderUpdate()
        bindToSearchUpdate()

        // Need for preload markets list, when bottom sheet it has not been opened yet
        quotesUpdatesScheduler.saveQuotesUpdateDate(Date())
        performFetch()
    }

    deinit {
        AppLogger.debug("PulseMarketWidgetViewModel deinit")
    }

    // MARK: - Public Implementation

    func bind(searchTextPublisher: some Publisher<String, Never>) {
        searchTextPublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchText in
                viewModel.searchText = searchText
            }
            .store(in: &bag)
    }

    func tryLoadAgain() {
        dataProvider.reset()
        performFetch()
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

    func pauseQuotesUpdates() {
        quotesUpdatesScheduler.suspend()
    }

    func resumeQuotesUpdates() {
        quotesUpdatesScheduler.resume()
    }
}

// MARK: - Private Implementation

private extension PulseMarketWidgetViewModel {
    func performFetch() {
        dataProvider.fetch(searchText.trimmed(), with: currentFetchFilter)
    }

    var currentFetchFilter: MarketsListDataProvider.Filter {
        guard isSearchActive else {
            return filterProvider.currentFilterValue
        }

        return MarketsListDataProvider.Filter(
            interval: filterProvider.currentFilterValue.interval,
            order: Constants.searchOrderType
        )
    }

    func bindToSearchUpdate() {
        $searchText
            .removeDuplicates()
            .dropFirst()
            .debounce(for: Constants.searchDebounceInterval, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.dataProvider.reset()
                viewModel.performFetch()
            }
            .store(in: &bag)
    }

    func bindToCurrencyCodeUpdate() {
        AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, newCurrencyCode in
                viewModel.marketCapFormatter = .init(divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList, baseCurrencyCode: newCurrencyCode, notationFormatter: .init())
                viewModel.dataProvider.reset()
                viewModel.performFetch()
            }
            .store(in: &bag)
    }

    func bindToOrderUpdate() {
        // Map selected chip id to MarketsListOrderType and update provider
        $filterSelectedId
            .dropFirst()
            .removeDuplicates()
            .receiveOnMain()
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
                    viewModel.performFetch()
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
                    viewModel.widgetsUpdateHandler.performUpdateLoading(state: .loading, for: .pulse)
                case .idle:
                    break
                case .failedToFetchData:
                    if viewModel.dataProvider.items.isEmpty {
                        viewModel.quotesUpdatesScheduler.cancelUpdates()
                    }

                    viewModel.widgetsUpdateHandler.performUpdateLoading(state: .error, for: .pulse)
                case .startInitialFetch, .cleared:
                    viewModel.widgetsUpdateHandler.performUpdateLoading(state: .loading, for: .pulse)
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
                viewModel.widgetsUpdateHandler.performUpdateLoading(state: .loaded, for: .pulse)
            }
            .store(in: &bag)

        widgetsUpdateHandler
            .widgetsUpdateStateEventPublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                switch state {
                case .loaded, .allFailed:
                    viewModel.displayLoadedStateRespectingSkeletonFloor()
                case .initialLoading:
                    viewModel.showSkeletons()
                case .reloading(let widgetTypes):
                    if widgetTypes.contains(.pulse) {
                        viewModel.showSkeletons()
                    }
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

    // MARK: - Skeleton Floor

    func showSkeletons() {
        skeletonFloor.start()

        tokenViewModelsState = .loading
        updateHeaderLoadingState()
    }

    func displayLoadedStateRespectingSkeletonFloor() {
        skeletonFloor.release { [weak self] in
            guard let self else { return }

            mapReadyForDisplay()
            clearIsFirstLoadingFlag()
            updateHeaderLoadingState()
        }
    }

    // MARK: - Map Widget States

    func mapReadyForDisplay() {
        switch dataProvider.lastEvent {
        case .appendedItems:
            let items = dataProvider.items.prefix(Constants.itemsOnListWidget)
            let tokenViewModelsToAppend = mapToItemViewModel(Array(items), offset: 0)
            tokenViewModelsState = .success(tokenViewModelsToAppend)
            updateQuotesSchedule(for: Set(items.map(\.id)))
        case .failedToFetchData(let error):
            tokenViewModelsState = .failure(error)
            analyticsService.logPulseMarketLoadError(error)
        case .loading, .startInitialFetch, .cleared:
            tokenViewModelsState = .loading
        case .idle:
            break
        }
    }

    func updateQuotesSchedule(for tokenIDs: Set<String>) {
        let hiddenTokenIDs = displayedTokenIDs.subtracting(tokenIDs)

        if hiddenTokenIDs.isNotEmpty {
            quotesUpdatesScheduler.stopUpdatingQuotes(for: hiddenTokenIDs)
        }

        displayedTokenIDs = tokenIDs
        quotesUpdatesScheduler.scheduleQuotesUpdate(for: tokenIDs)
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
            // Unlike the other widgets this one reloads on every chip tap, and hiding See all for each of those reads as a glitch
            headerLoadingState = isFirstLoading ? .first : .loaded
        case .success:
            headerLoadingState = .loaded
        case .failure:
            headerLoadingState = .failed
        }
    }
}

private extension PulseMarketWidgetViewModel {
    enum Constants {
        static let searchOrderType: MarketsListOrderType = .rating
        static let itemsOnListWidget = 5
        static let searchDebounceInterval: DispatchQueue.SchedulerTimeType.Stride = 0.45
    }
}
