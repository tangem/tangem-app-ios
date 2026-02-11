//
//  MarketsTokenListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt

final class MarketsTokenListViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Published private(set) var tokenViewModels: [MarketsItemViewModel] = []
    @Published private(set) var marketsRatingHeaderViewModel: MarketsRatingHeaderViewModel
    @Published private(set) var tokenListLoadingState: MarketsView.ListLoadingState = .idle

    // MARK: - Properties

    let resetScrollPositionPublisher = PassthroughSubject<Void, Never>()

    var isSearching: Bool {
        !currentSearchValue.isEmpty
    }

    var listDataControllerHotArea: MarketsListDataController.VisibleArea {
        listDataController.hotArea
    }

    var shouldDisplayShowTokensUnderCapView: Bool {
        let hasFilteredItems = tokenViewModels.count != dataProvider.items.count
        let dataLoaded = !dataProvider.isLoading

        return filterItemsBelowMarketCapThreshold && hasFilteredItems && dataLoaded
    }

    private weak var coordinator: MarketsRoutable?

    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
    private let filterProvider: MarketsListDataFilterProvider
    private let dataProvider: MarketsListDataProvider
    private let chartsHistoryProvider: MarketsListChartsHistoryProvider
    private let quotesUpdatesScheduler: MarketsQuotesUpdatesScheduler

    private lazy var listDataController: MarketsListDataController = .init(dataFetcher: self, cellsStateUpdater: self)

    private var marketCapFormatter: MarketCapFormatter
    private var bag = Set<AnyCancellable>()
    private var currentSearchValue: String = ""
    private var isViewVisible: Bool = false
    private var showItemsBelowCapThreshold: Bool = false

    private var filterItemsBelowMarketCapThreshold: Bool {
        isSearching && !showItemsBelowCapThreshold
    }

    // MARK: - Init

    init(
        listDataProvider: MarketsListDataProvider,
        listDataFilterProvider: MarketsListDataFilterProvider,
        quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper,
        quotesUpdatesScheduler: MarketsQuotesUpdatesScheduler,
        chartsHistoryProvider: MarketsListChartsHistoryProvider,
        coordinator: MarketsRoutable
    ) {
        dataProvider = listDataProvider
        filterProvider = listDataFilterProvider
        self.quotesRepositoryUpdateHelper = quotesRepositoryUpdateHelper
        self.quotesUpdatesScheduler = quotesUpdatesScheduler
        self.chartsHistoryProvider = chartsHistoryProvider
        self.coordinator = coordinator

        marketCapFormatter = .init(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )

        marketsRatingHeaderViewModel = MarketsRatingHeaderViewModel(provider: filterProvider)

        marketsRatingHeaderViewModel.delegate = self

        bindToCurrencyCodeUpdate()
        dataProviderBind()
        bindToHotArea()

        // Need for preload markets list, when bottom sheet it has not been opened yet
        quotesUpdatesScheduler.saveQuotesUpdateDate(Date())
        onFetch(with: "", by: filterProvider.currentFilterValue)
    }

    deinit {
        AppLogger.debug("MarketsTokenListViewModel deinit")
    }

    func onShowUnderCapAction() {
        Analytics.log(.marketsChartShowedTokensBelowCapThreshold)
        showItemsBelowCapThreshold = true

        if tokenViewModels.count == dataProvider.items.count, dataProvider.canFetchMore {
            dataProvider.fetchMore()
            return
        }

        let slicedArray = Array(dataProvider.items[tokenViewModels.count...])
        let itemsUnderCap = mapToItemViewModel(slicedArray, offset: tokenViewModels.count)
        tokenViewModels.append(contentsOf: itemsUnderCap)
    }
}

// MARK: - Public Implementation

extension MarketsTokenListViewModel {
    func onTryLoadList() {
        tokenListLoadingState = .loading
        onResetShowItemsBelowCapFlag()
        onFetch(with: currentSearchValue, by: filterProvider.currentFilterValue)
    }

    func onResetShowItemsBelowCapFlag() {
        showItemsBelowCapThreshold = false
    }

    func onFetch(with searchText: String = "", by filter: MarketsListDataProvider.Filter) {
        currentSearchValue = searchText
        dataProvider.fetch(searchText, with: filter)
    }

    func onRequestMiniCharts(forRange range: ClosedRange<Int>, interval: MarketsPriceIntervalType) {
        let items = tokenViewModels
        let itemsToFetch: Array<MarketsItemViewModel>.SubSequence
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
}

// MARK: - Private Implementation

private extension MarketsTokenListViewModel {
    func bindToCurrencyCodeUpdate() {
        AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, newCurrencyCode in
                viewModel.marketCapFormatter = .init(divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList, baseCurrencyCode: newCurrencyCode, notationFormatter: .init())
                viewModel.dataProvider.reset()
                viewModel.onFetch(with: viewModel.currentSearchValue, by: viewModel.filterProvider.currentFilterValue)
            }
            .store(in: &bag)
    }

    func bindToHotArea() {
        listDataController.hotAreaPublisher
            .dropFirst()
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map { $0.range }
            .combineLatest(filterProvider.filterPublisher.map(\.interval))
            .withWeakCaptureOf(self)
            .sink { items in
                let (viewModel, (hotAreaRange, interval)) = items
                viewModel.onRequestMiniCharts(forRange: hotAreaRange, interval: interval)
            }
            .store(in: &bag)
    }

    func dataProviderBind() {
        let dataProviderEventPipeline = dataProvider.$lastEvent
            .removeDuplicates()
            .share(replay: 1)

        dataProviderEventPipeline
            .filter { !$0.isAppendedItems }
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
                case .failedToFetchData(let error):
                    if viewModel.dataProvider.items.isEmpty {
                        Analytics.log(event: .marketsDataError, params: error.marketsAnalyticsParams)
                        viewModel.tokenListLoadingState = .error
                        viewModel.quotesUpdatesScheduler.cancelUpdates()
                    } else {
                        viewModel.tokenListLoadingState = .loading
                    }
                case .startInitialFetch, .cleared:
                    viewModel.tokenListLoadingState = .loading
                    viewModel.tokenViewModels.removeAll()
                    viewModel.resetScrollPositionPublisher.send(())
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
                guard case .appendedItems(let items, let lastPage) = event else {
                    return nil
                }

                let tokenViewModelsToAppend = viewModel.mapToItemViewModel(items, offset: viewModel.tokenViewModels.count)
                return (tokenViewModelsToAppend, lastPage)
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { (viewModel: MarketsTokenListViewModel, mappedEvent: ([MarketsItemViewModel], Bool)) in
                let (items, lastPage) = mappedEvent

                viewModel.tokenViewModels.append(contentsOf: items)

                if viewModel.dataProvider.items.isEmpty {
                    viewModel.tokenListLoadingState = .noResults
                    return
                }

                if lastPage {
                    viewModel.tokenListLoadingState = .allDataLoaded
                    return
                }

                viewModel.tokenListLoadingState = .idle
            }
            .store(in: &bag)
    }

    func mapToItemViewModel(_ list: [MarketsTokenModel], offset: Int) -> [MarketsItemViewModel] {
        let listToProcess = filterItemsBelowMarketCapIfNeeded(list)
        return listToProcess.enumerated().map { mapToTokenViewModel(index: $0 + offset, tokenItemModel: $1) }
    }

    func filterItemsBelowMarketCapIfNeeded(_ list: [MarketsTokenModel]) -> [MarketsTokenModel] {
        guard filterItemsBelowMarketCapThreshold else {
            return list
        }

        return list.filter { !($0.isUnderMarketCapLimit ?? false) }
    }

    func mapToTokenViewModel(index: Int, tokenItemModel: MarketsTokenModel) -> MarketsItemViewModel {
        return MarketsItemViewModel(
            index: index,
            tokenModel: tokenItemModel,
            marketCapFormatter: marketCapFormatter,
            prefetchDataSource: listDataController,
            chartsProvider: chartsHistoryProvider,
            filterProvider: filterProvider,
            onTapAction: { [weak self] in
                self?.logAnalyticsOnMarketChartOpen(
                    tokenSymbol: tokenItemModel.symbol,
                    marketCap: tokenItemModel.marketCap
                )

                self?.coordinator?.openMarketsTokenDetails(for: tokenItemModel)
            }
        )
    }

    func logAnalyticsOnMarketChartOpen(tokenSymbol: String, marketCap: Decimal?) {
        let analyticsParams: [Analytics.ParameterKey: String] = [
            .source: Analytics.ParameterValue.market.rawValue,
            .token: tokenSymbol.uppercased(),
        ]

        Analytics.log(event: .marketsChartScreenOpened, params: analyticsParams)
    }
}

extension MarketsTokenListViewModel: MarketsListDataFetcher {
    var canFetchMore: Bool {
        dataProvider.canFetchMore && tokenListLoadingState == .idle
    }

    var totalItems: Int {
        tokenViewModels.count
    }

    func fetchMore() {
        dataProvider.fetchMore()
    }
}

extension MarketsTokenListViewModel: MarketsOrderHeaderViewModelOrderDelegate {
    func orderActionButtonDidTap() {
        coordinator?.openFilterOrderBottonSheet(with: filterProvider)
    }
}

extension MarketsTokenListViewModel: MarketsListStateUpdater {
    func invalidateCells(in range: ClosedRange<Int>) {
        var invalidatedIds = Set<String>()
        for index in range {
            guard index < tokenViewModels.count else {
                break
            }

            let tokenViewModel = tokenViewModels[index]
            invalidatedIds.insert(tokenViewModel.tokenId)
        }

        quotesUpdatesScheduler.stopUpdatingQuotes(for: invalidatedIds)
    }

    func setupUpdates(for range: ClosedRange<Int>) {
        var idsToUpdate = Set<String>()
        for index in range {
            guard index < tokenViewModels.count else {
                break
            }

            let tokenViewModel = tokenViewModels[index]
            idsToUpdate.insert(tokenViewModel.tokenId)
        }

        quotesUpdatesScheduler.scheduleQuotesUpdate(for: idsToUpdate)
    }
}

private extension MarketsTokenListViewModel {
    enum Constants {
        static let filterRequiredReloadInterval: Set<MarketsListOrderType> = [.buyers, .gainers, .losers]
    }
}
