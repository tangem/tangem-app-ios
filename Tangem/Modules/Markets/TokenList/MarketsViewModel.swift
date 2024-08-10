//
//  MarketsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import Kingfisher

final class MarketsViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Published var alert: AlertBinder?
    @Published var tokenViewModels: [MarketsItemViewModel] = []
    @Published var marketsRatingHeaderViewModel: MarketsRatingHeaderViewModel
    @Published var tokenListLoadingState: MarketsView.ListLoadingState = .idle

    // MARK: - Properties

    @Published var isViewVisible: Bool = false

    let resetScrollPositionPublisher = PassthroughSubject<Void, Never>()

    var isSearching: Bool {
        !currentSearchValue.isEmpty
    }

    var shouldDisplayShowTokensUnderCapView: Bool {
        let hasFilteredItems = tokenViewModels.count != dataProvider.items.count
        let dataLoaded = !dataProvider.isLoading

        return filterItemsBelowMarketCapThreshold && hasFilteredItems && dataLoaded
    }

    private weak var coordinator: MarketsRoutable?

    private let filterProvider = MarketsListDataFilterProvider()
    private let dataProvider = MarketsListDataProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private let quotesUpdater = MarketsQuotesUpdater()
    private let imageCache = KingfisherManager.shared.cache

    private lazy var listDataController: MarketsListDataController = .init(dataProvider: dataProvider, viewVisibilityPublisher: $isViewVisible, cellsStateUpdater: self)

    private var bag = Set<AnyCancellable>()
    private var currentSearchValue: String = ""
    private var showItemsBelowCapThreshold: Bool = false

    private var filterItemsBelowMarketCapThreshold: Bool {
        isSearching && !showItemsBelowCapThreshold
    }

    // MARK: - Init

    init(
        searchTextPublisher: some Publisher<String, Never>,
        coordinator: MarketsRoutable
    ) {
        self.coordinator = coordinator

        marketsRatingHeaderViewModel = MarketsRatingHeaderViewModel(provider: filterProvider)
        marketsRatingHeaderViewModel.delegate = self

        searchTextBind(searchTextPublisher: searchTextPublisher)
        searchFilterBind(filterPublisher: filterProvider.filterPublisher)

        bind()
        dataProviderBind()

        // Need for preload markets list, when bottom sheet it has not been opened yet
        fetch(with: "", by: filterProvider.currentFilterValue)
    }

    func onBottomSheetAppear() {
        // Need for locked fetchMore process when bottom sheet not yet open
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isViewVisible = true
        }

        onAppearPrepareImageCache()

        Analytics.log(.marketsScreenOpened)
    }

    func onBottomSheetDisappear() {
        dataProvider.reset()
        // Need reset state bottom sheet for next open bottom sheet
        fetch(with: "", by: filterProvider.currentFilterValue)
        currentSearchValue = ""
        isViewVisible = false
        showItemsBelowCapThreshold = false
        chartsHistoryProvider.reset()
        onDisappearPrepareImageCache()
    }

    func fetchMore() {
        dataProvider.fetchMore()
    }

    func onShowUnderCapAction() {
        showItemsBelowCapThreshold = true

        if tokenViewModels.count == dataProvider.items.count, dataProvider.canFetchMore {
            dataProvider.fetchMore()
            return
        }

        tokenViewModels = mapToItemViewModel(dataProvider.items)
    }

    func onTryLoadList() {
        resetUI()
        fetch(with: currentSearchValue, by: filterProvider.currentFilterValue)
    }
}

// MARK: - Private Implementation

private extension MarketsViewModel {
    func fetch(with searchText: String = "", by filter: MarketsListDataProvider.Filter) {
        dataProvider.fetch(searchText, with: filter)
    }

    func searchTextBind(searchTextPublisher: (some Publisher<String, Never>)?) {
        searchTextPublisher?
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                guard viewModel.isViewVisible else {
                    return
                }

                if viewModel.currentSearchValue != value {
                    viewModel.resetUI()
                }

                viewModel.currentSearchValue = value
                viewModel.fetch(with: value, by: viewModel.dataProvider.lastFilterValue ?? viewModel.filterProvider.currentFilterValue)
            }
            .store(in: &bag)
    }

    func searchFilterBind(filterPublisher: (some Publisher<MarketsListDataProvider.Filter, Never>)?) {
        filterPublisher?
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                // If we change the sorting, we always rebuild the list.
                guard value.order == viewModel.dataProvider.lastFilterValue?.order else {
                    viewModel.fetch(with: viewModel.dataProvider.lastSearchTextValue ?? "", by: viewModel.filterProvider.currentFilterValue)
                    return
                }

                // If the sorting value has not changed, and order filter for losers or gainers, the order of the list may also change.
                // Otherwise, we just get new charts for a given interval.
                // The charts will also be updated when the list is updated
                if value.order == .losers || value.order == .gainers {
                    viewModel.fetch(with: viewModel.dataProvider.lastSearchTextValue ?? "", by: viewModel.filterProvider.currentFilterValue)
                } else {
                    viewModel.chartsHistoryProvider.fetch(
                        for: viewModel.dataProvider.items.map { $0.id },
                        with: viewModel.filterProvider.currentFilterValue.interval
                    )
                }
            }
            .store(in: &bag)
    }

    func bind() {
        $isViewVisible
            .withWeakCaptureOf(self)
            .sink { viewModel, isVisible in
                if isVisible {
                    viewModel.quotesUpdater.resumeUpdates()
                } else {
                    viewModel.quotesUpdater.pauseUpdates()
                }
            }
            .store(in: &bag)
    }

    func dataProviderBind() {
        dataProvider.$items
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, items in
                viewModel.chartsHistoryProvider.fetch(for: items.map { $0.id }, with: viewModel.filterProvider.currentFilterValue.interval)

                // [REDACTED_TODO_COMMENT]
                // Refactor this. Each time data provider receive next page - whole item models list recreated.
                viewModel.tokenViewModels = viewModel.mapToItemViewModel(items)
            })
            .store(in: &bag)

        dataProvider.$isLoading
            .combineLatest($tokenListLoadingState, $tokenViewModels)
            .filter { $0.0 && $0.1 == .loading && $0.2.isEmpty }
            .receive(on: DispatchQueue.main)
            .mapToVoid()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.resetScrollPositionPublisher.send(())
            }
            .store(in: &bag)

        dataProvider.$isLoading
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, isLoading in
                if viewModel.dataProvider.showError {
                    return
                }

                if isLoading {
                    viewModel.tokenListLoadingState = .loading
                    return
                }

                if viewModel.dataProvider.items.isEmpty {
                    viewModel.tokenListLoadingState = .noResults
                    return
                }

                if !viewModel.dataProvider.canFetchMore {
                    viewModel.tokenListLoadingState = .allDataLoaded
                    return
                }

                viewModel.tokenListLoadingState = .idle
            })
            .store(in: &bag)

        dataProvider.$showError
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, showError in
                if showError {
                    viewModel.resetUI()
                    viewModel.tokenListLoadingState = .error
                }
            })
            .store(in: &bag)
    }

    // MARK: - Private Implementation

    private func mapToItemViewModel(_ list: [MarketsTokenModel]) -> [MarketsItemViewModel] {
        let listToProcess = filterItemsBelowMarketCapIfNeeded(list)
        return listToProcess.enumerated().map { mapToTokenViewModel(index: $0, tokenItemModel: $1) }
    }

    private func filterItemsBelowMarketCapIfNeeded(_ list: [MarketsTokenModel]) -> [MarketsTokenModel] {
        guard filterItemsBelowMarketCapThreshold else {
            return list
        }

        return list.filter {
            guard let marketCap = $0.marketCap else {
                return false
            }

            return marketCap >= Constants.marketCapThreshold
        }
    }

    private func mapToTokenViewModel(index: Int, tokenItemModel: MarketsTokenModel) -> MarketsItemViewModel {
        let inputData = MarketsItemViewModel.InputData(
            index: index,
            id: tokenItemModel.id,
            name: tokenItemModel.name,
            symbol: tokenItemModel.symbol,
            marketCap: tokenItemModel.marketCap,
            marketRating: tokenItemModel.marketRating,
            priceValue: tokenItemModel.currentPrice,
            priceChangeStateValues: tokenItemModel.priceChangePercentage
        )

        return MarketsItemViewModel(
            inputData,
            prefetchDataSource: listDataController,
            chartsProvider: chartsHistoryProvider,
            filterProvider: filterProvider,
            onTapAction: { [weak self] in
                self?.coordinator?.openTokenMarketsDetails(for: tokenItemModel)
            }
        )
    }

    private func onAppearPrepareImageCache() {
        imageCache.memoryStorage.config.countLimit = 250
    }

    private func onDisappearPrepareImageCache() {
        imageCache.memoryStorage.removeAll()
        imageCache.memoryStorage.config.countLimit = .max
    }

    private func resetUI() {
        showItemsBelowCapThreshold = false
    }
}

extension MarketsViewModel: MarketsOrderHeaderViewModelOrderDelegate {
    func orderActionButtonDidTap() {
        coordinator?.openFilterOrderBottonSheet(with: filterProvider)
    }
}

extension MarketsViewModel: MarketsListStateUpdater {
    func invalidateCells(in range: ClosedRange<Int>) {
        var invalidatedIds = Set<String>()
        for index in range {
            guard index < tokenViewModels.count else {
                break
            }

            let tokenViewModel = tokenViewModels[index]
            invalidatedIds.insert(tokenViewModel.tokenId)
        }

        quotesUpdater.stopUpdatingQuotes(for: invalidatedIds)
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

        quotesUpdater.scheduleQuotesUpdate(for: idsToUpdate)
    }
}

private extension MarketsViewModel {
    enum Constants {
        static let marketCapThreshold: Decimal = 100_000.0
    }
}
