//
//  RealAssetsWidgetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation
import TangemLocalization

final class RealAssetsWidgetViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var categorySelection: RealAssetsCategorySelection?
    @Published private(set) var featuredViewModel: RealAssetsFeaturedViewModel?
    @Published private(set) var tokenViewModels: [MarketsItemViewModel] = []
    @Published private(set) var tokenListLoadingState: MarketsTokenListLoadingState = .loading
    @Published var selectedOrder: MarketsListOrderType = .rating
    @Published var selectedInterval: MarketsPriceIntervalType = .day

    // MARK: - Properties

    var orderOptions: [MarketsListOrderType] {
        filterProvider.supportedOrderTypes
    }

    var intervalOptions: [MarketsPriceIntervalType] {
        filterProvider.supportedPriceIntervalTypes
    }

    var isRegionRestrictionBannerVisible: Bool {
        categorySelection?.category.restricted ?? false
    }

    var regionRestrictionDescription: String {
        guard let regionName = categoriesSnapshot?.country.flatMap(Self.localizedRegionName(for:)) else {
            return Localization.marketsRealAssetsRegionRestrictionDescription
        }

        return Localization.marketsRealAssetsRegionRestrictionDescriptionRegion(regionName)
    }

    private weak var coordinator: RealAssetsWidgetRoutable?
    private let categoriesProvider: MarketsCategoriesProvider
    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper

    private let filterProvider: MarketsListDataFilterProvider
    private let dataProvider = MarketsListDataProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private let quotesUpdatesScheduler = MarketsQuotesUpdatesScheduler()

    private lazy var listDataController: MarketsListDataController = .init(dataFetcher: self, cellsStateUpdater: self)

    private var marketCapFormatter: MarketCapFormatter
    private var categoriesSnapshot: MarketsCategoriesSnapshot?
    private var categoriesLoadingTask: Task<Void, Never>?
    private var requestedCategoryId: String?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        categoriesProvider: MarketsCategoriesProvider,
        quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper,
        coordinator: RealAssetsWidgetRoutable?
    ) {
        self.categoriesProvider = categoriesProvider
        self.quotesRepositoryUpdateHelper = quotesRepositoryUpdateHelper
        self.coordinator = coordinator

        filterProvider = MarketsListDataFilterProvider(
            supportedOrderTypes: Constants.supportedOrderTypes,
            analyticsSection: .assets
        )

        marketCapFormatter = .init(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )

        bindToFilterSelection()
        bindToCurrencyCodeUpdate()
        bindToHotArea()
        dataProviderBind()

        quotesUpdatesScheduler.saveQuotesUpdateDate(Date())
        loadCategories()
    }

    deinit {
        categoriesLoadingTask?.cancel()
        AppLogger.debug("RealAssetsWidgetViewModel deinit")
    }

    // MARK: - Actions

    func tryLoadAgain() {
        guard categoriesSnapshot != nil else {
            loadCategories()
            return
        }

        featuredViewModel?.tryLoadAgain()
        tokenListLoadingState = .loading
        dataProvider.reset()
        dataProvider.fetch("", with: filterProvider.currentFilterValue)
    }

    func onCategoryChipTap() {
        guard let categoriesSnapshot, let categorySelection, let defaultSelection = defaultSelection(from: categoriesSnapshot) else {
            return
        }

        let input = RealAssetsCategoryFilterInput(
            categories: categoriesSnapshot.selectableCategories,
            selection: categorySelection,
            defaultSelection: defaultSelection,
            onApply: { [weak self] selection in
                guard let self else { return }

                Analytics.log(event: .marketsSelectCategory, params: analyticsParams(for: selection))
                select(selection)
            }
        )

        runTask(in: self) { @MainActor viewModel in
            viewModel.coordinator?.openRealAssetsCategoryFilter(with: input)
        }
    }

    func onCategoryClearTap() {
        guard let categoriesSnapshot else {
            return
        }

        if let umbrella = categoriesSnapshot.umbrellaCategory {
            select(RealAssetsCategorySelection(category: umbrella))
        } else if let defaultSelection = defaultSelection(from: categoriesSnapshot) {
            select(defaultSelection)
        }
    }

    func select(categoryId: String?) {
        guard let categoryId else {
            requestedCategoryId = nil
            return
        }

        guard let categoriesSnapshot else {
            requestedCategoryId = categoryId
            return
        }

        guard let selection = selection(for: categoryId, in: categoriesSnapshot) else {
            return
        }

        select(selection)
    }

    func pauseQuotesUpdates() {
        quotesUpdatesScheduler.suspend()
    }

    func resumeQuotesUpdates() {
        quotesUpdatesScheduler.resume()
    }
}

// MARK: - Categories

private extension RealAssetsWidgetViewModel {
    func loadCategories() {
        categoriesLoadingTask?.cancel()
        tokenListLoadingState = .loading

        let categoriesProvider = categoriesProvider

        categoriesLoadingTask = Task { @MainActor [weak self] in
            do {
                let snapshot = try await categoriesProvider.categories()

                guard let self else { return }

                guard let defaultSelection = defaultSelection(from: snapshot) else {
                    throw RealAssetsWidgetError.noCategories
                }

                categoriesSnapshot = snapshot
                makeFeaturedViewModel(from: snapshot)
                select(requestedSelection(from: snapshot) ?? defaultSelection)
            } catch {
                guard let self, !error.isCancellationError else { return }

                AppLogger.tag("Markets").error("Failed to load real assets categories", error: error)
                tokenListLoadingState = .error
            }
        }
    }

    func requestedSelection(from snapshot: MarketsCategoriesSnapshot) -> RealAssetsCategorySelection? {
        defer { requestedCategoryId = nil }

        return requestedCategoryId.flatMap { selection(for: $0, in: snapshot) }
    }

    func selection(for categoryId: String, in snapshot: MarketsCategoriesSnapshot) -> RealAssetsCategorySelection? {
        snapshot
            .selectableCategories
            .first { $0.code == categoryId || String($0.id) == categoryId }
            .map { RealAssetsCategorySelection(category: $0) }
    }

    func defaultSelection(from snapshot: MarketsCategoriesSnapshot) -> RealAssetsCategorySelection? {
        MarketsDefaultCategoryResolver
            .resolve(from: snapshot.selectableCategories, regionCode: snapshot.country)
            .map { RealAssetsCategorySelection(category: $0) }
    }

    static func localizedRegionName(for code: String) -> String? {
        Locale(identifier: Locale.appLanguageCode).localizedString(forRegionCode: code)
    }

    func makeFeaturedViewModel(from snapshot: MarketsCategoriesSnapshot) {
        guard let featuredCategory = snapshot.featuredCategory else {
            featuredViewModel = nil
            return
        }

        featuredViewModel = RealAssetsFeaturedViewModel(
            categoryId: featuredCategory.id,
            country: snapshot.country,
            onTokenTap: { [weak self] tokenModel in
                self?.onTokenTap(tokenModel)
            }
        )
    }

    func select(_ selection: RealAssetsCategorySelection) {
        guard categorySelection != selection else { return }

        categorySelection = selection

        if selection.category.restricted {
            Analytics.log(event: .marketsNotificationRegionNotSupported, params: analyticsParams(for: selection))
        }

        filterProvider.didSelectCategory(
            MarketsListDataFilterProvider.CategorySelection(
                categoryId: selection.category.id,
                sectorId: selection.sector?.id,
                country: categoriesSnapshot?.country
            )
        )
    }

    func analyticsParams(for selection: RealAssetsCategorySelection) -> [Analytics.ParameterKey: String] {
        var params: [Analytics.ParameterKey: String] = [.category: selection.analyticsValue]
        params[.section] = Analytics.MarketsSection.assets.rawValue
        return params
    }
}

// MARK: - Bindings

private extension RealAssetsWidgetViewModel {
    func bindToFilterSelection() {
        $selectedOrder
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, order in
                viewModel.filterProvider.didSelectMarketOrder(order)
            }
            .store(in: &bag)

        $selectedInterval
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, interval in
                viewModel.filterProvider.didSelectMarketPriceInterval(interval)
            }
            .store(in: &bag)

        filterProvider.filterPublisher
            .removeDuplicates()
            .filter { $0.categoryId != nil }
            .withWeakCaptureOf(self)
            .sink { viewModel, filter in
                viewModel.dataProvider.reset()
                viewModel.dataProvider.fetch("", with: filter)
            }
            .store(in: &bag)
    }

    func bindToCurrencyCodeUpdate() {
        AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, newCurrencyCode in
                viewModel.marketCapFormatter = .init(
                    divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
                    baseCurrencyCode: newCurrencyCode,
                    notationFormatter: DefaultAmountNotationFormatter()
                )

                guard viewModel.categoriesSnapshot != nil else { return }

                viewModel.dataProvider.reset()
                viewModel.dataProvider.fetch("", with: viewModel.filterProvider.currentFilterValue)
            }
            .store(in: &bag)
    }

    func bindToHotArea() {
        listDataController.hotAreaPublisher
            .dropFirst()
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { $0.range }
            .combineLatest(filterProvider.filterPublisher.map(\.interval).removeDuplicates())
            .withWeakCaptureOf(self)
            .sink { items in
                let (viewModel, (hotAreaRange, interval)) = items
                viewModel.requestMiniCharts(forRange: hotAreaRange, interval: interval)
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
                case .failedToFetchData:
                    if viewModel.dataProvider.items.isEmpty {
                        viewModel.tokenListLoadingState = .error
                        viewModel.quotesUpdatesScheduler.cancelUpdates()
                    } else {
                        viewModel.tokenListLoadingState = .loading
                    }
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

                viewModel.chartsHistoryProvider.fetch(
                    for: items.map(\.id),
                    with: viewModel.filterProvider.currentFilterValue.interval
                )

                viewModel.quotesRepositoryUpdateHelper.updateQuotes(
                    marketsTokens: items,
                    for: AppSettings.shared.selectedCurrencyCode
                )
            })
            .receive(on: DispatchQueue.main)
            .sink { viewModel, event in
                guard case .appendedItems(let items, let lastPage) = event else {
                    return
                }

                let tokenViewModelsToAppend = viewModel.mapToItemViewModel(items, offset: viewModel.tokenViewModels.count)
                viewModel.tokenViewModels.append(contentsOf: tokenViewModelsToAppend)

                if viewModel.dataProvider.items.isEmpty {
                    viewModel.tokenListLoadingState = .noResults
                } else if lastPage {
                    viewModel.tokenListLoadingState = .allDataLoaded
                } else {
                    viewModel.tokenListLoadingState = .idle
                }
            }
            .store(in: &bag)
    }

    func requestMiniCharts(forRange range: ClosedRange<Int>, interval: MarketsPriceIntervalType) {
        let items = tokenViewModels

        if items.isEmpty || items.count <= range.lowerBound {
            return
        }

        let itemsToFetch = items.count <= range.upperBound ? items[range.lowerBound...] : items[range]
        let tokenIDs = itemsToFetch.map(\.tokenId)

        DispatchQueue.global(qos: .userInitiated).async { [chartsHistoryProvider] in
            chartsHistoryProvider.fetch(for: tokenIDs, with: interval)
        }
    }

    func mapToItemViewModel(_ list: [MarketsTokenModel], offset: Int) -> [MarketsItemViewModel] {
        list.enumerated().map { index, tokenModel in
            MarketsItemViewModel(
                index: index + offset,
                tokenModel: tokenModel,
                marketCapFormatter: marketCapFormatter,
                prefetchDataSource: listDataController,
                chartsProvider: chartsHistoryProvider,
                filterProvider: filterProvider,
                onTapAction: { [weak self] in
                    self?.onTokenTap(tokenModel)
                }
            )
        }
    }

    func onTokenTap(_ tokenModel: MarketsTokenModel) {
        runTask(in: self) { @MainActor viewModel in
            viewModel.coordinator?.openMarketsTokenDetails(for: tokenModel)
        }
    }
}

// MARK: - MarketsListDataFetcher

extension RealAssetsWidgetViewModel: MarketsListDataFetcher {
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

// MARK: - MarketsListStateUpdater

extension RealAssetsWidgetViewModel: MarketsListStateUpdater {
    func invalidateCells(in range: ClosedRange<Int>) {
        quotesUpdatesScheduler.stopUpdatingQuotes(for: tokenIds(in: range))
    }

    func setupUpdates(for range: ClosedRange<Int>) {
        quotesUpdatesScheduler.scheduleQuotesUpdate(for: tokenIds(in: range))
    }

    private func tokenIds(in range: ClosedRange<Int>) -> Set<String> {
        let upperBound = min(range.upperBound, tokenViewModels.count - 1)

        guard range.lowerBound <= upperBound else {
            return []
        }

        return Set(tokenViewModels[range.lowerBound ... upperBound].map(\.tokenId))
    }
}

private extension RealAssetsWidgetViewModel {
    enum RealAssetsWidgetError: Error {
        case noCategories
    }

    enum Constants {
        /// The only orders the list endpoint accepts together with `categoryId`.
        static let supportedOrderTypes: [MarketsListOrderType] = [.rating, .gainers, .losers]
    }
}
