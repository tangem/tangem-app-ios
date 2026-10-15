//
//  PolymarketEventsBlockViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI

final class PolymarketEventsBlockViewModel: ObservableObject {
    @Published private(set) var categories: [PolymarketCategory] = [] {
        didSet { categoryTabs = categories.map { PolymarketCategoryTab(id: $0.id, title: $0.label) } }
    }

    @Published private(set) var eventCards: [PolymarketEventCard.Model] = []
    @Published private(set) var selectedCategoryID: Int?
    @Published private(set) var loadingState: LoadingState = .loading

    private(set) var categoryTabs: [PolymarketCategoryTab] = []

    var selectedCategoryTab: Binding<PolymarketCategoryTab> {
        Binding(
            get: { self.categoryTabs.first { $0.id == self.selectedCategoryID } ?? self.categoryTabs.first ?? PolymarketCategoryTab(id: 0, title: "") },
            set: { self.select(categoryID: $0.id) }
        )
    }

    var showsTabs: Bool {
        !categories.isEmpty || loadingState == .loading
    }

    private let apiProvider: PolymarketAPIProvider
    private let refreshCenter: PolymarketMainRefreshCenter
    private let activityHandler: PolymarketMainActivityHandler
    private let isRegionRestricted: () -> Bool
    private weak var routable: PolymarketEventOpeningRoutable?
    private let now: () -> Date
    private let reportOutdatedData: () -> Void

    private var feed = PolymarketFeedPages()
    private var cursor: String?
    private var hasNext = false
    private var cache: [Int?: CategoryState] = [:]
    private var visibleEventIDs: Set<String> = []
    private var refreshingPages: Set<PageKey> = []
    private var lastStaleReport: Date?

    private var loadingTask: Task<Void, Never>?
    private var visibilityTask: Task<Void, Never>?
    private var isPollingPaused = false
    private var hasVisibilityChangedDuringTick = false
    private let poller: PolymarketForegroundPoller

    init(
        apiProvider: PolymarketAPIProvider,
        refreshCenter: PolymarketMainRefreshCenter,
        activityHandler: PolymarketMainActivityHandler,
        isRegionRestricted: @escaping () -> Bool,
        routable: PolymarketEventOpeningRoutable,
        notificationCenter: NotificationCenter = .default,
        now: @escaping () -> Date = Date.init,
        reportOutdatedData: @escaping () -> Void = PolymarketEventsBlockViewModel.presentOutdatedDataToast
    ) {
        self.apiProvider = apiProvider
        self.refreshCenter = refreshCenter
        self.activityHandler = activityHandler
        self.isRegionRestricted = isRegionRestricted
        self.routable = routable
        self.now = now
        self.reportOutdatedData = reportOutdatedData
        poller = PolymarketForegroundPoller(interval: Constants.pollInterval, notificationCenter: notificationCenter)

        refreshCenter.register { [weak self] scope in
            await self?.refresh(scope: scope)
        }

        poller.start(
            onTick: { [weak self] in await self?.pollVisiblePages() },
            onPause: { [weak self] in self?.pausePolling() }
        )
        load()
    }
}

// MARK: - View actions

extension PolymarketEventsBlockViewModel {
    @MainActor
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .openEventDetails(let id):
            openEventDetails(eventID: id)
        case .retry:
            retry()
        case .loadNextPage, .retryNextPage:
            loadMore()
        case .onEventVisibilityChange(let id, let isVisible):
            updateVisibility(eventID: id, isVisible: isVisible)
        }
    }

    enum ViewAction {
        case openEventDetails(id: String)
        case retry
        case loadNextPage
        case retryNextPage
        case onEventVisibilityChange(id: String, isVisible: Bool)
    }
}

// MARK: - Actions

private extension PolymarketEventsBlockViewModel {
    func load() {
        loadingTask?.cancel()

        cache = [:]
        resetEvents()
        loadingState = .loading

        loadingTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.loadCategories()
        }
    }

    func retry() {
        guard !categories.isEmpty else {
            runTask(in: self) { @MainActor viewModel in
                await viewModel.refreshCenter.refresh(.accountFunds)
            }
            load()
            return
        }

        fetchEvents()
    }

    func select(categoryID: Int?) {
        guard selectedCategoryID != categoryID else { return }

        loadingTask?.cancel()
        cache[selectedCategoryID] = snapshot()
        selectedCategoryID = categoryID

        if let cached = cache[categoryID], !cached.feed.isEmpty {
            restore(cached)
        } else {
            fetchEvents()
        }
    }

    func loadMore() {
        guard hasNext, loadingState != .paginationLoading else { return }

        fetchEvents(more: true)
    }

    func openEventDetails(eventID: String) {
        let activityHandler = activityHandler

        routable?.openEventDetails(
            eventID: eventID,
            category: selectedCategory,
            onOrderPlaced: { [weak activityHandler] indexing in activityHandler?.orderPlaced(awaiting: indexing) }
        )
    }

    func selectOutcome(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String) {
        guard !isRegionRestricted() else {
            routable?.openRegionWarning()
            return
        }

        let activityHandler = activityHandler

        routable?.openOrder(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            request: .buy,
            onPlaced: { [weak activityHandler] indexing in activityHandler?.orderPlaced(awaiting: indexing) }
        )
    }
}

// MARK: - Refresh

private extension PolymarketEventsBlockViewModel {
    @MainActor
    func refresh(scope: PolymarketMainRefreshCenter.Scope) async {
        switch scope {
        case .full:
            await reloadFeed()
        case .balance, .accountFunds:
            break
        }
    }

    @MainActor
    func reloadFeed() async {
        loadingTask?.cancel()

        loadingTask = runTask(in: self) { @MainActor viewModel in
            if viewModel.categories.isEmpty {
                await viewModel.loadCategories()
            } else {
                await viewModel.reloadSelectedCategory()
            }
        }

        await loadingTask?.value
    }
}

// MARK: - Polling

private extension PolymarketEventsBlockViewModel {
    @MainActor
    func pollVisiblePages() async {
        isPollingPaused = false
        await refreshVisiblePages()
    }

    func pausePolling() {
        isPollingPaused = true
        visibilityTask?.cancel()
        visibilityTask = nil
        hasVisibilityChangedDuringTick = false
    }

    func updateVisibility(eventID: String, isVisible: Bool) {
        guard isVisible else {
            visibleEventIDs.remove(eventID)
            return
        }

        visibleEventIDs.insert(eventID)

        guard visibilityTask == nil else {
            hasVisibilityChangedDuringTick = true
            return
        }

        scheduleVisibilityTick()
    }

    func scheduleVisibilityTick() {
        guard !isPollingPaused, visibilityTask == nil else { return }

        visibilityTask = runTask(in: self) { @MainActor viewModel in
            try? await Task.sleep(for: .seconds(Constants.visibilitySettleDelay))

            guard !Task.isCancelled else { return }

            await viewModel.refreshVisiblePages()

            guard !Task.isCancelled else { return }

            viewModel.visibilityTask = nil

            if viewModel.hasVisibilityChangedDuringTick {
                viewModel.hasVisibilityChangedDuringTick = false
                viewModel.scheduleVisibilityTick()
            }
        }
    }

    @MainActor
    func refreshVisiblePages() async {
        let stalePageIDs = feed.stalePageIDs(
            showing: visibleEventIDs,
            now: now(),
            staleAfter: Constants.staleAfter,
            minimumInterval: Constants.pollInterval
        )

        let generation = feed.generation

        for pageID in stalePageIDs {
            guard generation == feed.generation else { return }

            await refresh(pageID: pageID)
        }
    }

    @MainActor
    func refresh(pageID: Int) async {
        let key = PageKey(generation: feed.generation, pageID: pageID)

        guard let page = feed.page(id: pageID), refreshingPages.insert(key).inserted else { return }

        defer { refreshingPages.remove(key) }

        let categoryID = selectedCategoryID
        feed.markAttempt(pageID: pageID, at: now())

        do {
            let refreshed = try await apiProvider.events(
                request: PolymarketEventsRequest(category: categoryID, limit: Constants.pageSize, cursor: page.requestCursor)
            )
            try Task.checkCancellation()

            guard key.generation == feed.generation, feed.merge(refreshed.events, into: pageID, at: now()) > 0 else {
                return
            }

            eventCards = feed.events.map(makeCard)
        } catch {
            guard !error.isCancellationError, key.generation == feed.generation else { return }

            PolymarketLogger.error("Failed to refresh a page of the events feed", error: error)

            let failures = feed.markFailure(pageID: pageID)

            if failures >= Constants.staleReportFailures, feed.pageIDs(showing: visibleEventIDs).contains(pageID) {
                reportStaleData()
            }
        }
    }

    func reportStaleData() {
        let now = now()

        if let lastStaleReport, now.timeIntervalSince(lastStaleReport) < Constants.staleReportCooldown {
            return
        }

        lastStaleReport = now
        reportOutdatedData()
    }
}

// MARK: - Outdated data

extension PolymarketEventsBlockViewModel {
    static func presentOutdatedDataToast() {
        Toast(view: WarningToast(text: Localization.predictionMainDataOutdated))
            .present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())
    }
}

// MARK: - Loading

private extension PolymarketEventsBlockViewModel {
    func events(category: Int?, cursor: String?) async throws -> PolymarketEventsPage {
        let request = PolymarketEventsRequest(category: category, limit: Constants.pageSize, cursor: cursor)

        do {
            return try await apiProvider.events(request: request)
        } catch {
            guard !error.isCancellationError else { throw error }

            try await Task.sleep(for: .seconds(Constants.silentRetryDelay))

            return try await apiProvider.events(request: request)
        }
    }

    @MainActor
    func loadCategories() async {
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

            apply(page: page, requestCursor: nil)
        } catch {
            handleFetchFailure(error)
        }
    }

    @MainActor
    func reloadSelectedCategory() async {
        let categoryID = selectedCategoryID

        do {
            let page = try await events(category: categoryID, cursor: nil)
            try Task.checkCancellation()

            cache[categoryID] = nil
            resetEvents()
            apply(page: page, requestCursor: nil)
        } catch {
            handleFetchFailure(error)
        }
    }

    func fetchEvents(more: Bool = false, emptyPages: Int = 0) {
        loadingTask?.cancel()

        if !more {
            resetEvents()
        }

        loadingState = feed.isEmpty ? .loading : .paginationLoading

        let categoryID = selectedCategoryID
        let requestCursor = more ? cursor : nil

        loadingTask = runTask(in: self) { @MainActor viewModel in
            do {
                let page = try await viewModel.events(category: categoryID, cursor: requestCursor)
                try Task.checkCancellation()

                viewModel.apply(page: page, requestCursor: requestCursor, emptyPages: emptyPages)
            } catch {
                viewModel.handleFetchFailure(error)
            }
        }
    }

    func apply(page: PolymarketEventsPage, requestCursor: String?, emptyPages: Int = 0) {
        let added = append(events: page.events, requestCursor: requestCursor)

        cursor = page.cursor
        hasNext = page.hasNext

        guard added > 0 || !page.hasNext || emptyPages >= Constants.maxEmptyPages else {
            fetchEvents(more: true, emptyPages: emptyPages + 1)
            return
        }

        loadingState = feed.isEmpty ? .noResults : (page.hasNext ? .loaded : .allDataLoaded)
    }

    func handleFetchFailure(_ error: Error) {
        guard !error.isCancellationError else { return }

        loadingState = feed.isEmpty ? .error : .paginationError
    }

    @discardableResult
    func append(events newEvents: [PolymarketEvent], requestCursor: String?) -> Int {
        let fresh = feed.append(events: newEvents, requestCursor: requestCursor, at: now())

        eventCards.append(contentsOf: fresh.map(makeCard))

        return fresh.count
    }

    var selectedCategory: PolymarketCategory? {
        categories.first { $0.id == selectedCategoryID }
    }

    func makeCard(for event: PolymarketEvent) -> PolymarketEventCard.Model {
        .make(
            event: event,
            category: nil,
            isInActivePredicts: false,
            onSelectOutcome: { [weak self] market, outcome in
                self?.selectOutcome(market: market, outcome: outcome, eventTitle: event.title)
            }
        )
    }

    func resetEvents() {
        feed.removeAll()
        eventCards = []
        cursor = nil
        hasNext = false
        refreshingPages = []
        visibilityTask?.cancel()
        visibilityTask = nil
        hasVisibilityChangedDuringTick = false
    }

    func snapshot() -> CategoryState {
        CategoryState(feed: feed, cursor: cursor, hasNext: hasNext)
    }

    func restore(_ state: CategoryState) {
        resetEvents()
        feed = state.feed
        eventCards = feed.events.map(makeCard)
        cursor = state.cursor
        hasNext = state.hasNext
        loadingState = state.hasNext ? .loaded : .allDataLoaded
    }

    var locale: String? {
        Locale.current.language.languageCode?.identifier
    }
}

// MARK: - Types

extension PolymarketEventsBlockViewModel {
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

private extension PolymarketEventsBlockViewModel {
    struct CategoryState {
        let feed: PolymarketFeedPages
        let cursor: String?
        let hasNext: Bool
    }

    struct PageKey: Hashable {
        let generation: UUID
        let pageID: Int
    }

    enum Constants {
        static let pageSize = 20
        static let silentRetryDelay: TimeInterval = 2
        static let maxEmptyPages = 3
        static let pollInterval: TimeInterval = 20
        static let staleAfter: TimeInterval = 20
        static let visibilitySettleDelay: TimeInterval = 0.5
        static let staleReportFailures = 3
        static let staleReportCooldown: TimeInterval = 300
        static let toastTopPadding: CGFloat = 20
    }
}
