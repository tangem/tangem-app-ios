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
    @Published private(set) var positionsState: PositionsState = .loading
    @Published private(set) var hadPositionsBefore = false
    @Published private(set) var isRetryingPositions = false
    @Published private(set) var hasFinishedPositions = false
    @Published private(set) var hasMorePositions = false
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
    private let positionsService: PolymarketPositionsService?
    private let userWalletId: UserWalletId
    private let presenceStore: PolymarketAccountPresenceStore = AppSettings.shared
    private let fundsArrivalTracker: PolymarketFundsArrivalTracker
    private let refreshCenter: PolymarketMainRefreshCenter
    private weak var coordinator: PolymarketMainRoutable?

    private var searchBag: Set<AnyCancellable> = []
    private let appStateObserver = AppStateObserver()
    private var bag: Set<AnyCancellable> = []

    private var events: [PolymarketEvent] = []
    private var cursor: String?
    private var hasNext = false
    private var cache: [Int?: CategoryState] = [:]
    private var loadingTask: Task<Void, Never>?
    private var positionsTask: Task<Void, Never>?
    private var contentRefreshTask: Task<Void, Never>?
    private var orderTask: Task<Void, Never>?
    private var claimTask: Task<Void, Never>?
    private var openPositions: [PolymarketPosition] = []
    private var positionsGoneLocally: Set<String> = []

    init(
        apiProvider: PolymarketAPIProvider,
        geoblockStateProvider: PolymarketGeoblockStateProvider,
        positionsService: PolymarketPositionsService?,
        fundsArrivalTracker: PolymarketFundsArrivalTracker,
        userWalletId: UserWalletId,
        refreshCenter: PolymarketMainRefreshCenter,
        coordinator: PolymarketMainRoutable
    ) {
        self.apiProvider = apiProvider
        self.geoblockStateProvider = geoblockStateProvider
        search = PolymarketSearchViewModel(apiProvider: apiProvider)
        self.positionsService = positionsService
        self.fundsArrivalTracker = fundsArrivalTracker
        self.userWalletId = userWalletId
        self.refreshCenter = refreshCenter
        self.coordinator = coordinator
        search.coordinator = self

        bindSearch()
        bindGeoblockState()
        bindFundsArrival()
        bindApplicationState()
        startContentRefresh()
        load()
        loadPositions()
    }

    deinit {
        orderTask?.cancel()
        claimTask?.cancel()
        contentRefreshTask?.cancel()
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

    private func bindApplicationState() {
        appStateObserver.start { [weak self] isInBackground in
            guard let self else { return }

            if isInBackground {
                stopContentRefresh()
            } else {
                startContentRefresh(refreshingNow: true)
            }
        }
    }

    private func stopContentRefresh() {
        contentRefreshTask?.cancel()
        contentRefreshTask = nil
        positionsTask?.cancel()
    }

    private func startContentRefresh(refreshingNow: Bool = false) {
        contentRefreshTask?.cancel()

        contentRefreshTask = Task { @MainActor [weak self] in
            if refreshingNow, let self {
                loadPositions()
                await refreshVisibleEvents()
            }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Constants.contentRefreshInterval))

                guard !Task.isCancelled, let self else { return }

                loadPositions()
                await refreshVisibleEvents()
            }
        }
    }

    // MARK: - Positions

    func loadPositions(userInitiated: Bool = false) {
        guard let positionsService else {
            positionsState = .loaded([])
            return
        }

        positionsTask?.cancel()

        let isSilentRound = positionsState == .failed && !userInitiated

        if case .loaded = positionsState {} else if !isSilentRound {
            // Read once per round: the flag is written by this very load, and a mid-flight flip would
            // swap one state for another in front of the user.
            hadPositionsBefore = presenceStore.hadPositions(userWalletId: userWalletId)
            isRetryingPositions = isRetryingPositions || userInitiated
            positionsState = .loading
        }

        positionsTask = runTask(in: self) { @MainActor viewModel in
            do {
                async let finished = Self.probeFinishedPositions(service: positionsService)
                let page = try await Self.activePositions(service: positionsService)
                try Task.checkCancellation()

                viewModel.openPositions = Array(viewModel.stillOpen(page.positions).prefix(Constants.positionsShown))
                viewModel.hasMorePositions = page.hasNext || page.receivedCount > viewModel.openPositions.count

                let probed = await finished

                try Task.checkCancellation()

                if let probed {
                    viewModel.hasFinishedPositions = probed
                }

                viewModel.isRetryingPositions = false

                if probed == nil, viewModel.openPositions.isEmpty, !viewModel.hasFinishedPositions {
                    viewModel.positionsState = .failed
                    return
                }

                if viewModel.openPositions.isNotEmpty || viewModel.hasFinishedPositions {
                    viewModel.presenceStore.markPositionsExisted(for: viewModel.userWalletId)
                    viewModel.hadPositionsBefore = true
                }

                withAnimation(.easeInOut(duration: Constants.listAnimationDuration)) {
                    viewModel.positionsState = .loaded(
                        viewModel.openPositions.map(PolymarketPositionRow.Model.make(position:))
                    )
                }
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketLogger.error("Failed to load the open positions", error: error)

                viewModel.isRetryingPositions = false

                if case .loaded = viewModel.positionsState { return }

                viewModel.positionsState = .failed
            }
        }
    }

    func stillOpen(_ positions: [PolymarketPosition]) -> [PolymarketPosition] {
        positionsGoneLocally.formIntersection(positions.map(\.id))

        return positions.filter { !positionsGoneLocally.contains($0.id) }
    }

    private static func probeFinishedPositions(service: PolymarketPositionsService) async -> Bool? {
        do {
            return try await closedPositionsExist(service: service)
        } catch {
            guard !error.isCancellationError else { return nil }

            PolymarketLogger.error("Failed to probe the closed positions", error: error)
            return nil
        }
    }

    private static func closedPositionsExist(service: PolymarketPositionsService) async throws -> Bool {
        do {
            return try await closedPositionsPage(service: service).receivedCount > 0
        } catch {
            guard (error as? PolymarketAPIError)?.isTransient == true else { throw error }

            try await Task.sleep(for: .seconds(Constants.positionsRetryDelay))

            return try await closedPositionsPage(service: service).receivedCount > 0
        }
    }

    private static func closedPositionsPage(
        service: PolymarketPositionsService
    ) async throws -> PolymarketClosedPositionsPage {
        try await service.closedPositions(
            sort: .closedAt,
            ascending: false,
            limit: Constants.finishedProbeLimit,
            offset: 0
        )
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

    private static func activePositions(service: PolymarketPositionsService) async throws -> PolymarketPositionsPage {
        do {
            return try await service.activePositions(limit: Constants.positionsLimit)
        } catch {
            guard (error as? PolymarketAPIError)?.isTransient == true else { throw error }

            try await Task.sleep(for: .seconds(Constants.positionsRetryDelay))

            return try await service.activePositions(limit: Constants.positionsLimit)
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
        case .openPositionDetails(let id):
            openPosition(id: id)
        case .openMyPositions(let tab):
            openMyPositions(tab: tab)
        case .retryPositions:
            loadPositions(userInitiated: true)
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

    @MainActor
    private func openMyPositions(tab: PolymarketPositionsTab) {
        coordinator?.openMyPositions(
            tab: tab,
            onOrderPlaced: { [weak self] indexing in self?.orderPlaced(awaiting: indexing) },
            onClaimed: { [weak self] claimed in self?.claimed(claimed) }
        )
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
        coordinator?.openEventDetails(
            eventID: eventID,
            category: category,
            onOrderPlaced: { [weak self] indexing in self?.orderPlaced(awaiting: indexing) }
        )
    }

    private func selectOutcome(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String) {
        guard !isRegionRestricted else {
            coordinator?.openRegionWarning()
            return
        }

        coordinator?.openOrder(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            request: .buy,
            onPlaced: { [weak self] indexing in self?.orderPlaced(awaiting: indexing) }
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
        case openPositionDetails(id: String)
        case openMyPositions(PolymarketPositionsTab)
        case retryPositions
        case openEventDetails(id: String)
        case retryEvents
        case loadNextPage
        case retryNextPage
    }
}

extension PolymarketMainViewModel {
    enum PositionsState: Equatable {
        case loading
        case loaded([PolymarketPositionRow.Model])
        case failed
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
        static let positionsLimit = 10
        static let positionsShown = 3
        static let positionsRetryDelay: TimeInterval = 1
        static let silentRetryDelay: TimeInterval = 2
        static let finishedProbeLimit = 1
        static let listAnimationDuration: TimeInterval = 0.25
    }
}

// MARK: - Positions

extension PolymarketMainViewModel {
    private func openPosition(id: String) {
        guard let position = openPositions.first(where: { $0.id == id }) else { return }

        guard !position.isRedeemable, position.settlement?.isResolved != true else {
            Task { @MainActor in
                coordinator?.openRedeem(position: position, onClaimed: { [weak self] claimed in self?.claimed(claimed) })
            }
            return
        }

        coordinator?.openPositionDetails(
            position: position,
            onOrderPlaced: { [weak self] indexing in self?.orderPlaced(awaiting: indexing) }
        )
    }
}

// MARK: - Claims

private extension PolymarketMainViewModel {
    func claimed(_ position: PolymarketPosition?) {
        claimTask?.cancel()

        fundsArrivalTracker.startAwaitingBalanceChange()

        claimTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.refreshBalance()
            viewModel.loadPositions()
            await viewModel.positionsTask?.value

            guard !Task.isCancelled else { return }

            viewModel.drop(claimed: position)
        }
    }

    /// The claimed shares are burned, but the list keeps handing the position back until the indexer notices.
    func drop(claimed position: PolymarketPosition?) {
        guard let position else { return }

        positionsGoneLocally.insert(position.id)

        guard openPositions.contains(where: { $0.id == position.id }) else { return }

        openPositions = openPositions.filter { $0.id != position.id }
        positionsState = .loaded(openPositions.map(PolymarketPositionRow.Model.make(position:)))
    }
}

// MARK: - Orders

private extension PolymarketMainViewModel {
    func orderPlaced(awaiting indexing: PolymarketOrderIndexing) {
        orderTask?.cancel()

        fundsArrivalTracker.startAwaitingBalanceChange()

        orderTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.refreshBalance()

            let traded = await indexing.value

            guard !Task.isCancelled else { return }

            await viewModel.refreshBalance()
            viewModel.loadPositions()
            await viewModel.positionsTask?.value

            guard !Task.isCancelled else { return }

            viewModel.apply(traded: traded)
        }
    }

    /// The list endpoint lags behind the traded outcome, so the reload can still hand back the pre-fill position.
    func apply(traded position: PolymarketPosition?) {
        guard let position else { return }

        if position.isEmptied {
            positionsGoneLocally.insert(position.id)
        }

        guard openPositions.contains(where: { $0.id == position.id }) else { return }

        openPositions = position.size > 0
            ? openPositions.map { $0.id == position.id ? position : $0 }
            : openPositions.filter { $0.id != position.id }

        positionsState = .loaded(openPositions.map(PolymarketPositionRow.Model.make(position:)))
    }
}

// MARK: - Refresh

extension PolymarketMainViewModel {
    @MainActor
    func refresh() async {
        geoblockStateProvider.refresh()
        loadingTask?.cancel()

        async let blocks: Void = refreshCenter.refresh(.full)

        loadPositions()

        if categories.isEmpty {
            await loadCategories()
        } else {
            await reloadSelectedCategory()
        }

        await blocks
    }

    @MainActor
    func refreshBalance() async {
        await refreshCenter.refresh(.balance)
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
