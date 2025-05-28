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
import CombineExt
import Kingfisher
import struct TangemUIUtils.AlertBinder

final class MarketsViewModel: MarketsBaseViewModel {
    private typealias SearchInput = MainBottomSheetHeaderViewModel.SearchInput

    // MARK: - Injected & Published Properties

    @Published var alert: AlertBinder?
    @Published private(set) var tokenViewModels: [MarketsItemViewModel] = []
    @Published private(set) var headerViewModel: MainBottomSheetHeaderViewModel
    @Published private(set) var marketsRatingHeaderViewModel: MarketsRatingHeaderViewModel
    @Published private(set) var tokenListLoadingState: MarketsView.ListLoadingState = .idle
    @Published private(set) var stakingNotificationState: MarketsStakingNotificationState = .hidden

    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.viewHierarchySnapshotter) private var viewHierarchySnapshotter: ViewHierarchySnapshotting
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManager

    // MARK: - Properties

    let resetScrollPositionPublisher = PassthroughSubject<Void, Never>()

    var isSearching: Bool {
        !currentSearchValue.isEmpty
    }

    override var overlayContentHidingProgress: CGFloat {
        // Prevents unwanted content hiding (see [REDACTED_INFO]
        isViewVisible ? super.overlayContentHidingProgress : 1.0
    }

    var shouldDisplayShowTokensUnderCapView: Bool {
        let hasFilteredItems = tokenViewModels.count != dataProvider.items.count
        let dataLoaded = !dataProvider.isLoading

        return filterItemsBelowMarketCapThreshold && hasFilteredItems && dataLoaded
    }

    private weak var coordinator: MarketsRoutable?

    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
    private let filterProvider = MarketsListDataFilterProvider()
    private let dataProvider = MarketsListDataProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private let quotesUpdatesScheduler = MarketsQuotesUpdatesScheduler()
    private let imageCache = KingfisherManager.shared.cache
    private let marketsNotificationsManager: MarketsNotificationsManager
    private lazy var listDataController: MarketsListDataController = .init(dataFetcher: self, cellsStateUpdater: self)
    private(set) var navigationActionHandler: NavigationActionHandling?

    private var marketCapFormatter: MarketCapFormatter
    private var bag = Set<AnyCancellable>()
    private var currentSearchValue: String = ""
    private var isViewVisible: Bool = false
    private var isBottomSheetExpanded: Bool = false
    private(set) var showItemsBelowCapThreshold: Bool = false

    private var filterItemsBelowMarketCapThreshold: Bool {
        isSearching && !showItemsBelowCapThreshold
    }

    // MARK: - Init

    init(
        quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper,
        coordinator: MarketsRoutable
    ) {
        self.quotesRepositoryUpdateHelper = quotesRepositoryUpdateHelper
        self.coordinator = coordinator

        marketsNotificationsManager = MarketsNotificationsManager(dataProvider: dataProvider)

        marketCapFormatter = .init(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )

        headerViewModel = MainBottomSheetHeaderViewModel()
        marketsRatingHeaderViewModel = MarketsRatingHeaderViewModel(provider: filterProvider)

        // Our view is initially presented when the sheet is collapsed, hence the `0.0` initial value.
        super.init(overlayContentProgressInitialValue: 0.0)

        headerViewModel.delegate = self
        marketsRatingHeaderViewModel.delegate = self

        searchTextBind(publisher: headerViewModel.enteredSearchInputPublisher)
        searchFilterBind(filterPublisher: filterProvider.filterPublisher)
        stakingNotificationBind(filterProvider.filterPublisher)

        bindToCurrencyCodeUpdate()
        dataProviderBind()
        bindToMainBottomSheetUIManager()
        bindToHotArea()
        bindToIncomingActionManager()
        createNavigationActionHandler()

        // Need for preload markets list, when bottom sheet it has not been opened yet
        quotesUpdatesScheduler.saveQuotesUpdateDate(Date())
        fetch(with: "", by: filterProvider.currentFilterValue)
    }

    deinit {
        AppLogger.debug("MarketsViewModel deinit")
    }

    /// Handles `SwiftUI.View.onAppear(perform:)`.
    func onViewAppear() {
        isViewVisible = true
    }

    /// Handles `SwiftUI.View.onDisappear(perform:)`.
    func onViewDisappear() {
        isViewVisible = false
    }

    func onOverlayContentStateChange(_ state: OverlayContentState) {
        switch state {
        case .expanded:
            // Need for locked fetchMore process when bottom sheet not yet open
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isBottomSheetExpanded = true
            }

            onAppearPrepareImageCache()

            Analytics.log(.marketsScreenOpened)

            headerViewModel.onBottomSheetExpand(isTapGesture: state.isTapGesture)
            quotesUpdatesScheduler.forceUpdate()
        case .collapsed:
            isBottomSheetExpanded = false
            quotesUpdatesScheduler.cancelUpdates()
        }
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

    func onTryLoadList() {
        tokenListLoadingState = .loading
        resetShowItemsBelowCapFlag()
        fetch(with: currentSearchValue, by: filterProvider.currentFilterValue)
    }

    func openStakingFiter() {
        Analytics.log(.marketsStakingMoreInfo)
        filterProvider.didSelectMarketOrder(.staking)
    }

    func closeStakingNotification() {
        Analytics.log(.marketsStakingPromoClosed)
        AppSettings.shared.startWalletUsageDate = .distantFuture
    }
}

// MARK: - Private Implementation

private extension MarketsViewModel {
    func fetch(with searchText: String = "", by filter: MarketsListDataProvider.Filter) {
        dataProvider.fetch(searchText, with: filter)
    }

    private func searchTextBind(publisher: some Publisher<SearchInput, Never>) {
        publisher
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            // Ensure that clear input event will be delivered immediately
            .merge(with: publisher.filter { $0 == .clearInput })
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchInput in
                switch searchInput {
                case .textInput(let value):
                    if viewModel.currentSearchValue.compare(value) != .orderedSame {
                        viewModel.resetShowItemsBelowCapFlag()
                    }

                    viewModel.currentSearchValue = value
                    let currentFilter = viewModel.dataProvider.lastFilterValue ?? viewModel.filterProvider.currentFilterValue

                    // Always use rating sorting for search
                    let searchFilter = MarketsListDataProvider.Filter(
                        interval: currentFilter.interval,
                        order: value.isEmpty ? currentFilter.order : .rating
                    )

                    viewModel.fetch(with: value, by: searchFilter)
                case .clearInput:
                    if viewModel.currentSearchValue.isEmpty {
                        return
                    }

                    viewModel.resetShowItemsBelowCapFlag()
                    viewModel.currentSearchValue = ""
                    viewModel.fetch(with: "", by: viewModel.filterProvider.currentFilterValue)
                }
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

                // If the sorting value has not changed, and order filter for losers or gainers or buyers, the order of the list may also change.
                // Otherwise, we just get new charts for a given interval.
                // The charts will also be updated when the list is updated
                if Constants.filterRequiredReloadInterval.contains(value.order) {
                    viewModel.fetch(with: viewModel.dataProvider.lastSearchTextValue ?? "", by: viewModel.filterProvider.currentFilterValue)
                } else {
                    let hotAreaRange = viewModel.listDataController.hotArea
                    viewModel.requestMiniCharts(forRange: hotAreaRange.range, interval: value.interval)
                }
            }
            .store(in: &bag)
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
                viewModel.requestMiniCharts(forRange: hotAreaRange, interval: interval)
            }
            .store(in: &bag)
    }

    private func stakingNotificationBind(_ filterPublisher: some Publisher<MarketsListDataProvider.Filter, Never>) {
        marketsNotificationsManager.stakingNotificationState(from: filterPublisher)
            .sink { [weak self] state in
                if case .visible = state {
                    Analytics.log(.marketsNoticeStakingPromo)
                }
                self?.stakingNotificationState = state
            }
            .store(in: &bag)
    }

    private func bindToIncomingActionManager() {
        incomingActionManager.didReceiveNavigationAction
            .sink { [weak self] _ in
                guard let self else { return }
                incomingActionManager.becomeFirstResponder(self)
            }
            .store(in: &bag)
    }

    private func createNavigationActionHandler() {
        if let coordinator {
            navigationActionHandler = MarketsNavigationActionHandler(
                coordinator: coordinator,
                bottomSheetPosition: { [weak self] in
                    guard let self else {
                        return .unknown
                    }

                    return isBottomSheetExpanded ? .expanded : .collapsed
                }
            )
        }
    }

    func requestMiniCharts(forRange range: ClosedRange<Int>, interval: MarketsPriceIntervalType) {
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

                    guard viewModel.isBottomSheetExpanded else {
                        return
                    }

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
            .sink { (viewModel: MarketsViewModel, mappedEvent: ([MarketsItemViewModel], Bool)) in
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

    func bindToMainBottomSheetUIManager() {
        mainBottomSheetUIManager
            .footerSnapshotUpdateTriggerPublisher
            .sink(receiveValue: weakify(self, forFunction: MarketsViewModel.updateFooterSnapshot))
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

    func onAppearPrepareImageCache() {
        imageCache.memoryStorage.config.countLimit = 250
    }

    func resetShowItemsBelowCapFlag() {
        showItemsBelowCapThreshold = false
    }

    func updateFooterSnapshot() {
        let lightAppearanceSnapshotImage = viewHierarchySnapshotter.makeSnapshotViewImage(
            afterScreenUpdates: true,
            isOpaque: true,
            overrideUserInterfaceStyle: .light
        )
        let darkAppearanceSnapshotImage = viewHierarchySnapshotter.makeSnapshotViewImage(
            afterScreenUpdates: true,
            isOpaque: true,
            overrideUserInterfaceStyle: .dark
        )

        mainBottomSheetUIManager.setFooterSnapshots(
            lightAppearanceSnapshotImage: lightAppearanceSnapshotImage,
            darkAppearanceSnapshotImage: darkAppearanceSnapshotImage
        )
    }

    private func logAnalyticsOnMarketChartOpen(tokenSymbol: String, marketCap: Decimal?) {
        let analyticsParams: [Analytics.ParameterKey: String] = [
            .source: Analytics.ParameterValue.market.rawValue,
            .token: tokenSymbol.uppercased(),
        ]

        Analytics.log(event: .marketsChartScreenOpened, params: analyticsParams)
    }
}

extension MarketsViewModel: MarketsListDataFetcher {
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

extension MarketsViewModel: MainBottomSheetHeaderViewModelDelegate {
    func isViewVisibleForHeaderViewModel(_ viewModel: MainBottomSheetHeaderViewModel) -> Bool {
        return isViewVisible
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

private extension MarketsViewModel {
    enum Constants {
        static let filterRequiredReloadInterval: Set<MarketsListOrderType> = [.buyers, .gainers, .losers]
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

import Moya
import Alamofire

extension Error {
    var marketsAnalyticsParams: [Analytics.ParameterKey: String] {
        var analyticsParams = [Analytics.ParameterKey: String]()

        analyticsParams[.errorMessage] = (self as? LocalizedError)?.localizedDescription
        analyticsParams[.errorCode] = marketsErrorCode(for: self)
        analyticsParams[.errorType] = marketsErrorType(for: self).rawValue

        return analyticsParams
    }

    private func marketsErrorCode(for: Error) -> String {
        if let moyaError = self as? MoyaError,
           case .statusCode(let response) = moyaError {
            return String(response.statusCode)
        } else {
            return Analytics.ParameterValue.marketsErrorCodeIsNotHTTPError.rawValue
        }
    }

    private func marketsErrorType(for error: Error) -> Analytics.ParameterValue {
        switch self {
        case _ as MarketsTokenHistoryChartMapper.ParsingError:
            return .custom
        case let moyaError as MoyaError where moyaError.isStatusCodeError:
            return .marketsErrorTypeHTTP
        case let moyaError as MoyaError:
            guard let underlyingError = moyaError.underlyingError else {
                fallthrough
            }
            return marketsErrorType(forUnderlyingMoyaError: underlyingError)
        default:
            return .unknown
        }
    }

    private func marketsErrorType(forUnderlyingMoyaError error: Error) -> Analytics.ParameterValue {
        if let afError = error as? AFError,
           case .sessionTaskFailed(let urlError as URLError) = afError,
           urlError.code == .timedOut {
            return .marketsErrorTypeTimeout
        }

        return .marketsErrorTypeNetwork
    }
}

private extension MoyaError {
    var underlyingError: Error? {
        switch self {
        case .underlying(let error, _): error
        default: nil
        }
    }

    var isStatusCodeError: Bool {
        switch self {
        case .statusCode: true
        default: false
        }
    }
}
