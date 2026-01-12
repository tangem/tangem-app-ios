//
//  MarketsSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import struct TangemUIUtils.AlertBinder

final class MarketsSearchViewModel: MarketsBaseViewModel {
    private typealias SearchInput = MainBottomSheetHeaderViewModel.SearchInput

    // MARK: - Published Properties

    @Published private(set) var headerViewModel: MainBottomSheetHeaderViewModel
    @Published private(set) var marketsRatingHeaderViewModel: MarketsRatingHeaderViewModel
    @Published private(set) var tokenListViewModel: MarketsTokenListViewModel
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var yieldModeNotificationVisible = false

    let resetScrollPositionPublisher = PassthroughSubject<Void, Never>()

    override var overlayContentHidingProgress: CGFloat {
        // Prevents unwanted content hiding (see [REDACTED_INFO]
        isViewVisible ? super.overlayContentHidingProgress : 1.0
    }

    // MARK: - Private Properties

    private weak var coordinator: MarketsRoutable?

    private let filterProvider = MarketsListDataFilterProvider()
    private let dataProvider = MarketsListDataProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
    private let quotesUpdatesScheduler = MarketsQuotesUpdatesScheduler()
    private let marketsNotificationsManager: MarketsNotificationsManager

    private var marketCapFormatter: MarketCapFormatter
    private var bag = Set<AnyCancellable>()

    private var currentSearchValue: String = ""
    private var isViewVisible: Bool = false
    private var isBottomSheetExpanded: Bool = false
    private var showItemsBelowCapThreshold: Bool = false

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

        tokenListViewModel = MarketsTokenListViewModel(
            listDataProvider: dataProvider,
            listDataFilterProvider: filterProvider,
            quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper,
            quotesUpdatesScheduler: quotesUpdatesScheduler,
            chartsHistoryProvider: chartsHistoryProvider,
            coordinator: coordinator
        )

        // Our view is initially presented when the sheet is collapsed, hence the `0.0` initial value.
        super.init(overlayContentProgressInitialValue: 0.0)

        headerViewModel.delegate = self
        marketsRatingHeaderViewModel.delegate = self
        bindChildViewModels()

        searchTextBind(publisher: headerViewModel.enteredSearchInputPublisher)
        searchFilterBind(filterPublisher: filterProvider.filterPublisher)

        yieldModeNotificationBind(filterProvider.filterPublisher)
    }

    deinit {
        AppLogger.debug("MarketsSearchViewModel deinit")
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
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.bottomSheetExpandedDelay) {
                self.isBottomSheetExpanded = true
            }

            Analytics.log(.marketsScreenOpened)

            headerViewModel.onBottomSheetExpand(isTapGesture: state.isTapGesture)
            quotesUpdatesScheduler.forceUpdate()
        case .collapsed:
            isBottomSheetExpanded = false
            quotesUpdatesScheduler.cancelUpdates()
        }
    }

    func onTryLoadList() {
        tokenListViewModel.onTryLoadList()
    }

    func openYieldModeFiter() {
        Analytics.log(.marketsYieldModeMoreInfo)
        filterProvider.didSelectMarketOrder(.yield)
    }

    func closeYieldModeNotification() {
        Analytics.log(.marketsYieldModePromoClosed)
        AppSettings.shared.showMarketsYieldModeNotification = false
    }

    func onSearchButtonAction() {
        isSearching = true

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.searchFieldAnimationDelay) {
            self.headerViewModel.inputShouldBecomeFocused = true
        }
    }
}

// MARK: - Private Implementation

private extension MarketsSearchViewModel {
    func bindChildViewModels() {
        tokenListViewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
    }

    func reset() {
        tokenListViewModel.onResetShowItemsBelowCapFlag()
        currentSearchValue = ""
        tokenListViewModel.onFetch(with: "", by: filterProvider.currentFilterValue)
    }

    private func yieldModeNotificationBind(_ filterPublisher: some Publisher<MarketsListDataProvider.Filter, Never>) {
        marketsNotificationsManager.yieldNotificationVisible(from: filterPublisher)
            .sink { [weak self] visible in
                if visible {
                    Analytics.log(.marketsNoticeYieldModePromo)
                }
                self?.yieldModeNotificationVisible = visible
            }
            .store(in: &bag)
    }

    private func searchTextBind(publisher: some Publisher<SearchInput, Never>) {
        publisher
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            // Ensure that clear and cancel input events will be delivered immediately
            .merge(with: publisher.filter { $0 == .clearInput || $0 == .cancelInput })
            .removeDuplicates { lhs, rhs in
                switch (lhs, rhs) {
                case (.textInput(let lhsValue), .textInput(let rhsValue)):
                    return lhsValue == rhsValue
                default:
                    return false
                }
            }
            .withWeakCaptureOf(self)
            .sink { viewModel, searchInput in
                switch searchInput {
                case .textInput(let value):
                    if viewModel.currentSearchValue.compare(value) != .orderedSame {
                        viewModel.tokenListViewModel.onResetShowItemsBelowCapFlag()
                    }

                    viewModel.currentSearchValue = value
                    let currentFilter = viewModel.dataProvider.lastFilterValue ?? viewModel.filterProvider.currentFilterValue

                    // Always use rating sorting for search
                    let searchFilter = MarketsListDataProvider.Filter(
                        interval: currentFilter.interval,
                        order: value.isEmpty ? currentFilter.order : .rating
                    )

                    viewModel.tokenListViewModel.onFetch(with: value, by: searchFilter)
                case .clearInput:
                    if viewModel.currentSearchValue.isEmpty {
                        return
                    }

                    viewModel.reset()
                case .cancelInput:
                    viewModel.isSearching = false
                    viewModel.reset()
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
                    viewModel.tokenListViewModel.onFetch(
                        with: viewModel.dataProvider.lastSearchTextValue ?? "",
                        by: viewModel.filterProvider.currentFilterValue
                    )
                    return
                }

                // If the sorting value has not changed, and order filter for losers or gainers or buyers, the order of the list may also change.
                // Otherwise, we just get new charts for a given interval.
                // The charts will also be updated when the list is updated
                if Constants.filterRequiredReloadInterval.contains(value.order) {
                    viewModel.tokenListViewModel.onFetch(
                        with: viewModel.dataProvider.lastSearchTextValue ?? "",
                        by: viewModel.filterProvider.currentFilterValue
                    )
                } else {
                    let hotAreaRange = viewModel.tokenListViewModel.listDataControllerHotArea
                    viewModel.tokenListViewModel.onRequestMiniCharts(forRange: hotAreaRange.range, interval: value.interval)
                }
            }
            .store(in: &bag)
    }
}

extension MarketsSearchViewModel: MainBottomSheetHeaderViewModelDelegate {
    func isViewVisibleForHeaderViewModel(_ viewModel: MainBottomSheetHeaderViewModel) -> Bool {
        return isViewVisible
    }
}

extension MarketsSearchViewModel: MarketsOrderHeaderViewModelOrderDelegate {
    func orderActionButtonDidTap() {
        coordinator?.openFilterOrderBottonSheet(with: filterProvider)
    }
}

private extension MarketsSearchViewModel {
    enum Constants {
        static let filterRequiredReloadInterval: Set<MarketsListOrderType> = [.buyers, .gainers, .losers]

        /// Need for locked fetchMore process when bottom sheet not yet open
        static let bottomSheetExpandedDelay: Double = 0.5

        /// Need for smooth switching animation
        static let searchFieldAnimationDelay: Double = 0.3
    }
}
