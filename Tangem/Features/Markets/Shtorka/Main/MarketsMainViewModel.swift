//
//  MarketsMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import Kingfisher
import TangemLocalization
import TangemFoundation

final class MarketsMainViewModel: MarketsBaseViewModel {
    private typealias SearchInput = MainBottomSheetHeaderViewModel.SearchInput

    // MARK: - Injected & Published Properties

    @Published private(set) var isSearching: Bool = false
    @Published private(set) var widgetsViewState: WidgetsViewState = .present([])

    @Published private(set) var headerViewModel: MainBottomSheetHeaderViewModel
    @Published private(set) var tokenListViewModel: MarketsTokenListViewModel

    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.viewHierarchySnapshotter) private var viewHierarchySnapshotter: ViewHierarchySnapshotting
    @Injected(\.marketsWidgetsProvider) private var widgetsProvider: MarketsMainWidgetsProvider
    @Injected(\.marketsWidgetsUpdateHandler) private var widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler

    // MARK: - Properties

    var headerTitle: String {
        Localization.feedMarketAndNews
    }

    var headerDate: String {
        let dateString = headerDateFormatter.string(from: Date())
        return dateString.capitalized(with: headerDateFormatter.locale)
    }

    override var overlayContentHidingProgress: CGFloat {
        // Prevents unwanted content hiding (see [REDACTED_INFO]
        isViewVisible ? super.overlayContentHidingProgress : 1.0
    }

    private weak var coordinator: MarketsMainRoutable?

    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
    private let filterProvider = MarketsListDataFilterProvider()
    private let dataProvider = MarketsListDataProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private let quotesUpdatesScheduler = MarketsQuotesUpdatesScheduler()
    private let marketsNotificationsManager: MarketsNotificationsManager

    private var bag = Set<AnyCancellable>()

    private var currentSearchValue: String = ""
    private var isViewVisible: Bool = false
    private var isBottomSheetExpanded: Bool = false

    private lazy var headerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return formatter
    }()

    // MARK: - Init

    init(quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper, coordinator: MarketsMainRoutable) {
        self.quotesRepositoryUpdateHelper = quotesRepositoryUpdateHelper
        self.coordinator = coordinator

        headerViewModel = MainBottomSheetHeaderViewModel()
        marketsNotificationsManager = MarketsNotificationsManager(dataProvider: dataProvider)

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

        searchTextBind(publisher: headerViewModel.enteredSearchInputPublisher)
        bindToWidgetsProvider()

        widgetsProvider.reloadWidgets()
    }

    deinit {
        AppLogger.debug("MarketsMainViewModel deinit")
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
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.bottomSheetExpandedDelay) {
                self.isBottomSheetExpanded = true
            }

            headerViewModel.onBottomSheetExpand(isTapGesture: state.isTapGesture)
        case .collapsed:
            isBottomSheetExpanded = false
        }
    }

    // MARK: - Actions

    func onTryLoadAgain() {
        widgetsProvider.reloadWidgets()
    }
}

// MARK: - Private Implementation

private extension MarketsMainViewModel {
    private func searchTextBind(publisher: some Publisher<SearchInput, Never>) {
        publisher
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            // Ensure that clear input event will be delivered immediately
            .merge(with: publisher.filter { $0 == .clearInput })
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchInput in
                viewModel.isSearching = true

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
                case .clearInput, .cancelInput:
                    viewModel.isSearching = false

                    if viewModel.currentSearchValue.isEmpty {
                        return
                    }

                    viewModel.tokenListViewModel.onResetShowItemsBelowCapFlag()
                    viewModel.currentSearchValue = ""
                    viewModel.tokenListViewModel.onFetch(with: "", by: viewModel.filterProvider.currentFilterValue)
                }
            }
            .store(in: &bag)
    }

    func bindToWidgetsProvider() {
        widgetsProvider
            .widgetsPublisher
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, widgets in
                let widgetItems = widgets
                    .filter(\.isEnabled)
                    .sorted(by: \.order)
                    .compactMap {
                        viewModel.mapToWidgetItem(widgetModel: $0)
                    }

                viewModel.widgetsViewState = .present(widgetItems)
            }
            .store(in: &bag)

        widgetsUpdateHandler
            .widgetsUpdateStateEventPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                if case .allWidgetsWithError = state {
                    viewModel.widgetsViewState = .error
                }
            }
            .store(in: &bag)
    }

    func bindToMainBottomSheetUIManager() {
        mainBottomSheetUIManager
            .footerSnapshotUpdateTriggerPublisher
            .sink(receiveValue: weakify(self, forFunction: MarketsMainViewModel.updateFooterSnapshot))
            .store(in: &bag)
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

    func mapToWidgetItem(widgetModel: MarketsWidgetModel) -> WidgetStateItem? {
        let contentItem: WidgetContentItem

        switch widgetModel.type {
        case .market:
            let viewModel = TopMarketWidgetViewModel(
                widgetType: widgetModel.type,
                widgetsUpdateHandler: widgetsUpdateHandler,
                quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper,
                coordinator: coordinator
            )
            contentItem = .top(viewModel)
        case .news:
            let viewModel = NewsWidgetViewModel(
                widgetType: widgetModel.type,
                widgetsUpdateHandler: widgetsUpdateHandler,
                coordinator: coordinator
            )
            contentItem = .news(viewModel)
        case .earn:
            return nil
        case .pulse:
            let viewModel = PulseMarketWidgetViewModel(
                widgetType: widgetModel.type,
                widgetsUpdateHandler: widgetsUpdateHandler,
                quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper,

                coordinator: coordinator
            )
            contentItem = .pulse(viewModel)
        }

        return WidgetStateItem(type: widgetModel.type, content: contentItem)
    }
}

extension MarketsMainViewModel: MainBottomSheetHeaderViewModelDelegate {
    func isViewVisibleForHeaderViewModel(_ viewModel: MainBottomSheetHeaderViewModel) -> Bool {
        return isViewVisible
    }
}

extension MarketsMainViewModel {
    enum WidgetsViewState: Hashable {
        case present([WidgetStateItem])
        case error
    }

    struct WidgetStateItem: Identifiable, Hashable {
        var id: MarketsWidgetType.ID {
            type.id
        }

        let type: MarketsWidgetType
        let content: WidgetContentItem
    }

    enum WidgetContentItem: Identifiable, Hashable {
        case top(TopMarketWidgetViewModel)
        case pulse(PulseMarketWidgetViewModel)
        case news(NewsWidgetViewModel)

        var id: MarketsWidgetType {
            switch self {
            case .top:
                return .market
            case .pulse:
                return .pulse
            case .news:
                return .news
            }
        }

        static func == (lhs: MarketsMainViewModel.WidgetContentItem, rhs: MarketsMainViewModel.WidgetContentItem) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id.rawValue)
        }
    }
}

private extension MarketsMainViewModel {
    enum Constants {
        static let filterRequiredReloadInterval: Set<MarketsListOrderType> = [.buyers, .gainers, .losers]

        /// Need for locked fetchMore process when bottom sheet not yet open
        static let bottomSheetExpandedDelay: Double = 0.5
    }
}
