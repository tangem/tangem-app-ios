//
//  PolymarketMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

final class PolymarketMainViewModel: ObservableObject {
    @Published private(set) var categories: [PolymarketCategory] = [] {
        didSet { categoryTabs = categories.map { PolymarketCategoryTab(id: $0.id, title: $0.label) } }
    }

    @Published private(set) var eventCards: [PolymarketEventCard.Model] = []
    @Published private(set) var selectedCategoryID: Int?
    @Published private(set) var loadingState: LoadingState = .loading
    @Published private(set) var isTabsPinned = false
    @Published private(set) var isRegionRestricted = false
    @Published private(set) var isAwaitingFunds = false
    @Published private(set) var isSearching = false
    @Published var isSearchFieldActive = false
    @Published var searchQuery = ""

    let search: PolymarketSearchViewModel

    private(set) var categoryTabs: [PolymarketCategoryTab] = []

    var selectedCategoryTab: Binding<PolymarketCategoryTab> {
        Binding(
            get: { self.categoryTabs.first { $0.id == self.selectedCategoryID } ?? self.categoryTabs.first ?? PolymarketCategoryTab(id: 0, title: "") },
            set: { self.select(categoryID: $0.id) }
        )
    }

    private let apiProvider: PolymarketAPIProvider
    private let geoblockStateProvider: PolymarketGeoblockStateProvider
    private let fundsArrivalTracker: PolymarketFundsArrivalTracker
    private let refreshCenter: PolymarketMainRefreshCenter
    private let activityHandler: PolymarketMainActivityHandler
    private weak var coordinator: PolymarketMainRoutable?

    private var searchBag: Set<AnyCancellable> = []
    private let poller = PolymarketForegroundPoller(interval: Constants.contentRefreshInterval)
    private var bag: Set<AnyCancellable> = []

    private var events: [PolymarketEvent] = []
    private var cursor: String?
    private var hasNext = false
    private var cache: [Int?: CategoryState] = [:]
    private var loadingTask: Task<Void, Never>?

    init(
        apiProvider: PolymarketAPIProvider,
        geoblockStateProvider: PolymarketGeoblockStateProvider,
        fundsArrivalTracker: PolymarketFundsArrivalTracker,
        refreshCenter: PolymarketMainRefreshCenter,
        activityHandler: PolymarketMainActivityHandler,
        coordinator: PolymarketMainRoutable
    ) {
        self.apiProvider = apiProvider
        self.geoblockStateProvider = geoblockStateProvider
        search = PolymarketSearchViewModel(apiProvider: apiProvider)
        self.fundsArrivalTracker = fundsArrivalTracker
        self.refreshCenter = refreshCenter
        self.activityHandler = activityHandler
        self.coordinator = coordinator
        search.coordinator = self

        bindSearch()
        bindGeoblockState()
        bindFundsArrival()
        poller.start(onTick: { [weak self] in await self?.refreshVisibleEvents() })
        load()
    }

    private func bindSearch() {
        $searchQuery
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, query in viewModel.search.query = query }
            .store(in: &searchBag)

        $isSearchFieldActive
            .filter { $0 }
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in viewModel.isSearching = true }
            .store(in: &searchBag)
    }

    private func bindFundsArrival() {
        fundsArrivalTracker
            .$isAwaitingFunds
            .receiveOnMain()
            .assign(to: &$isAwaitingFunds)
    }

    private func bindGeoblockState() {
        geoblockStateProvider
            .statePublisher
            .map(\.isBlocked)
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isRestricted in
                viewModel.isRegionRestricted = isRestricted

                if isRestricted {
                    viewModel.coordinator?.openRegionWarning()
                }
            }
            .store(in: &bag)
    }

    private func events(category: Int?, cursor: String?) async throws -> PolymarketEventsPage {
        let request = PolymarketEventsRequest(category: category, limit: Constants.pageSize, cursor: cursor)

        do {
            return try await apiProvider.events(request: request)
        } catch {
            guard !error.isCancellationError else { throw error }

            try await Task.sleep(for: .seconds(Constants.silentRetryDelay))

            return try await apiProvider.events(request: request)
        }
    }

    // MARK: - View actions

    @MainActor
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .close:
            dismiss()
        case .openHowItWorks:
            openHowItWorks()
        case .openSupportChat:
            openSupportChat()
        case .cancelSearch:
            exitSearch()
        case .onTabsMove(let minY, let navBarHeight):
            updatePinnedState(tabsMinY: minY, navBarHeight: navBarHeight)
        case .openEventDetails(let id):
            openEventDetails(eventID: id)
        case .retryEvents:
            retry()
        case .loadNextPage, .retryNextPage:
            loadMore()
        }
    }

    // MARK: - Actions

    private func load() {
        loadingTask?.cancel()

        cache = [:]
        resetEvents()
        loadingState = .loading

        loadingTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.loadCategories()
        }
    }

    private func retry() {
        guard !categories.isEmpty else {
            runTask(in: self) { @MainActor viewModel in
                await viewModel.refreshCenter.refresh(.accountFunds)
            }
            load()
            return
        }

        fetchEvents()
    }

    private func select(categoryID: Int?) {
        guard selectedCategoryID != categoryID else { return }

        loadingTask?.cancel()
        cache[selectedCategoryID] = snapshot()
        selectedCategoryID = categoryID

        if let cached = cache[categoryID], !cached.events.isEmpty {
            restore(cached)
        } else {
            fetchEvents()
        }
    }

    private func loadMore() {
        guard hasNext, loadingState != .paginationLoading else { return }

        fetchEvents(more: true)
    }

    private func dismiss() {
        coordinator?.dismiss()
    }

    @MainActor
    private func openHowItWorks() {
        coordinator?.openHowItWorks()
    }

    @MainActor
    private func openSupportChat() {
        coordinator?.openSupportChat()
    }

    private func exitSearch() {
        isSearching = false
        isSearchFieldActive = false
        searchQuery = ""
        search.reset()
    }

    private func openEventDetails(eventID: String) {
        openEventDetails(eventID: eventID, category: selectedCategory)
    }

    private func updatePinnedState(tabsMinY: CGFloat, navBarHeight: CGFloat) {
        let pinned = tabsMinY <= navBarHeight
        if pinned != isTabsPinned {
            isTabsPinned = pinned
        }
    }

    // MARK: - Private

    @MainActor
    private func loadCategories() async {
        do {
            let categories = try await apiProvider.categories(locale: locale)
            try Task.checkCancellation()

            guard let firstCategoryID = categories.first?.id else {
                loadingState = .error
                return
            }

            self.categories = categories
            selectedCategoryID = firstCategoryID

            let page = try await events(category: firstCategoryID, cursor: nil)
            try Task.checkCancellation()

            apply(page: page)
        } catch {
            handleFetchFailure(error)
        }
    }

    @MainActor
    private func refreshVisibleEvents() async {
        guard !events.isEmpty else { return }

        let categoryID = selectedCategoryID

        do {
            let page = try await events(category: categoryID, cursor: nil)
            try Task.checkCancellation()

            guard categoryID == selectedCategoryID else { return }

            replaceVisibleEvents(with: page.events)
        } catch {
            guard !error.isCancellationError else { return }

            PolymarketLogger.error("Failed to refresh the events feed", error: error)
        }
    }

    @MainActor
    private func replaceVisibleEvents(with refreshed: [PolymarketEvent]) {
        let byID = Dictionary(refreshed.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        events = events.map { byID[$0.id] ?? $0 }
        eventCards = events.map(makeCard)
    }

    @MainActor
    private func reloadSelectedCategory() async {
        let categoryID = selectedCategoryID

        do {
            let page = try await events(category: categoryID, cursor: nil)
            try Task.checkCancellation()

            guard categoryID == selectedCategoryID else { return }

            cache[categoryID] = nil
            resetEvents()
            apply(page: page)
        } catch {
            handleFetchFailure(error)
        }
    }

    private func fetchEvents(more: Bool = false) {
        loadingTask?.cancel()

        if !more {
            resetEvents()
        }

        loadingState = events.isEmpty ? .loading : .paginationLoading

        let categoryID = selectedCategoryID
        let requestCursor = more ? cursor : nil

        loadingTask = runTask(in: self) { @MainActor viewModel in
            do {
                let page = try await viewModel.events(category: categoryID, cursor: requestCursor)
                try Task.checkCancellation()

                viewModel.apply(page: page)
            } catch {
                viewModel.handleFetchFailure(error)
            }
        }
    }

    private func apply(page: PolymarketEventsPage) {
        let added = append(events: page.events)

        cursor = page.cursor
        hasNext = page.hasNext

        guard added > 0 || !page.hasNext else {
            fetchEvents(more: true)
            return
        }

        loadingState = events.isEmpty ? .noResults : (page.hasNext ? .loaded : .allDataLoaded)
    }

    private func handleFetchFailure(_ error: Error) {
        guard !error.isCancellationError else { return }

        if !events.isEmpty, Self.isStaleCursorFailure(error) {
            cursor = nil
        }

        loadingState = events.isEmpty ? .error : .paginationError
    }

    private static func isStaleCursorFailure(_ error: Error) -> Bool {
        guard case .http(let statusCode, _) = error as? PolymarketAPIError else { return false }

        return statusCode == Constants.staleCursorStatusCode
    }

    @discardableResult
    private func append(events newEvents: [PolymarketEvent]) -> Int {
        var known = Set(events.map(\.id))
        let fresh = newEvents.filter { known.insert($0.id).inserted }

        events.append(contentsOf: fresh)
        eventCards.append(contentsOf: fresh.map(makeCard))

        return fresh.count
    }

    private func openEventDetails(eventID: String, category: PolymarketCategory?) {
        let activityHandler = activityHandler

        coordinator?.openEventDetails(
            eventID: eventID,
            category: category,
            onOrderPlaced: { [weak activityHandler] indexing in activityHandler?.orderPlaced(awaiting: indexing) }
        )
    }

    private func selectOutcome(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String) {
        guard !isRegionRestricted else {
            coordinator?.openRegionWarning()
            return
        }

        let activityHandler = activityHandler

        coordinator?.openOrder(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            request: .buy,
            onPlaced: { [weak activityHandler] indexing in activityHandler?.orderPlaced(awaiting: indexing) }
        )
    }

    private var selectedCategory: PolymarketCategory? {
        categories.first { $0.id == selectedCategoryID }
    }

    private func makeCard(for event: PolymarketEvent) -> PolymarketEventCard.Model {
        .make(
            event: event,
            category: nil,
            isInActivePredicts: false,
            onSelectOutcome: { [weak self] market, outcome in
                self?.selectOutcome(market: market, outcome: outcome, eventTitle: event.title)
            }
        )
    }

    private func resetEvents() {
        events = []
        eventCards = []
        cursor = nil
        hasNext = false
    }

    private func snapshot() -> CategoryState {
        CategoryState(events: events, cursor: cursor, hasNext: hasNext)
    }

    private func restore(_ state: CategoryState) {
        resetEvents()
        append(events: state.events)
        cursor = state.cursor
        hasNext = state.hasNext
        loadingState = state.hasNext ? .loaded : .allDataLoaded
    }

    private var locale: String? {
        Locale.current.language.languageCode?.identifier
    }
}

extension PolymarketMainViewModel {
    enum ViewAction {
        case close
        case openHowItWorks
        case openSupportChat
        case cancelSearch
        case onTabsMove(minY: CGFloat, navBarHeight: CGFloat)
        case openEventDetails(id: String)
        case retryEvents
        case loadNextPage
        case retryNextPage
    }
}

extension PolymarketMainViewModel {
    enum LoadingState: Equatable {
        case loading
        case error
        case noResults
        case loaded
        case allDataLoaded
        case paginationLoading
        case paginationError
    }
}

private extension PolymarketMainViewModel {
    struct CategoryState {
        let events: [PolymarketEvent]
        let cursor: String?
        let hasNext: Bool
    }

    enum Constants {
        static let pageSize = 20
        static let staleCursorStatusCode = 502

        static let contentRefreshInterval: TimeInterval = 20
        static let silentRetryDelay: TimeInterval = 2
    }
}

// MARK: - Refresh

extension PolymarketMainViewModel {
    @MainActor
    func refresh() async {
        geoblockStateProvider.refresh()
        loadingTask?.cancel()

        async let blocks: Void = refreshCenter.refresh(.full)

        if categories.isEmpty {
            await loadCategories()
        } else {
            await reloadSelectedCategory()
        }

        await blocks
    }
}

// MARK: - PolymarketSearchRoutable protocol conformance

extension PolymarketMainViewModel: PolymarketSearchRoutable {
    func openEventDetailsFromSearch(eventID: String) {
        isSearchFieldActive = false
        openEventDetails(eventID: eventID, category: nil)
    }

    func openOrderFromSearch(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String) {
        isSearchFieldActive = false
        selectOutcome(market: market, outcome: outcome, eventTitle: eventTitle)
    }
}
