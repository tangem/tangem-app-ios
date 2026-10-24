//
//  PolymarketEventsBlockViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
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

    private var events: [PolymarketEvent] = []
    private var cursor: String?
    private var hasNext = false
    private var cache: [Int?: CategoryState] = [:]

    private var loadingTask: Task<Void, Never>?
    private let poller: PolymarketForegroundPoller

    init(
        apiProvider: PolymarketAPIProvider,
        refreshCenter: PolymarketMainRefreshCenter,
        activityHandler: PolymarketMainActivityHandler,
        isRegionRestricted: @escaping () -> Bool,
        routable: PolymarketEventOpeningRoutable,
        notificationCenter: NotificationCenter = .default
    ) {
        self.apiProvider = apiProvider
        self.refreshCenter = refreshCenter
        self.activityHandler = activityHandler
        self.isRegionRestricted = isRegionRestricted
        self.routable = routable
        poller = PolymarketForegroundPoller(interval: Constants.contentRefreshInterval, notificationCenter: notificationCenter)

        refreshCenter.register { [weak self] scope in
            await self?.refresh(scope: scope)
        }

        poller.start(onTick: { [weak self] in await self?.refreshVisibleEvents() })
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
        }
    }

    enum ViewAction {
        case openEventDetails(id: String)
        case retry
        case loadNextPage
        case retryNextPage
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

        if let cached = cache[categoryID], !cached.events.isEmpty {
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
            loadingTask?.cancel()

            loadingTask = runTask(in: self) { @MainActor viewModel in
                if viewModel.categories.isEmpty {
                    await viewModel.loadCategories()
                } else {
                    await viewModel.reloadSelectedCategory()
                }
            }

            await loadingTask?.value
        case .balance, .accountFunds:
            break
        }
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

            apply(page: page)
        } catch {
            handleFetchFailure(error)
        }
    }

    @MainActor
    func refreshVisibleEvents() async {
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
    func replaceVisibleEvents(with refreshed: [PolymarketEvent]) {
        let byID = Dictionary(refreshed.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        events = events.map { byID[$0.id] ?? $0 }
        eventCards = events.map(makeCard)
    }

    @MainActor
    func reloadSelectedCategory() async {
        let categoryID = selectedCategoryID

        do {
            let page = try await events(category: categoryID, cursor: nil)
            try Task.checkCancellation()

            cache[categoryID] = nil
            resetEvents()
            apply(page: page)
        } catch {
            handleFetchFailure(error)
        }
    }

    func fetchEvents(more: Bool = false, emptyPages: Int = 0) {
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

                viewModel.apply(page: page, emptyPages: emptyPages)
            } catch {
                viewModel.handleFetchFailure(error)
            }
        }
    }

    func apply(page: PolymarketEventsPage, emptyPages: Int = 0) {
        let added = append(events: page.events)

        cursor = page.cursor
        hasNext = page.hasNext

        guard added > 0 || !page.hasNext || emptyPages >= Constants.maxEmptyPages else {
            fetchEvents(more: true, emptyPages: emptyPages + 1)
            return
        }

        loadingState = events.isEmpty ? .noResults : (page.hasNext ? .loaded : .allDataLoaded)
    }

    func handleFetchFailure(_ error: Error) {
        guard !error.isCancellationError else { return }

        if !events.isEmpty, Self.isStaleCursorFailure(error) {
            cursor = nil
        }

        loadingState = events.isEmpty ? .error : .paginationError
    }

    static func isStaleCursorFailure(_ error: Error) -> Bool {
        guard case .http(let statusCode, _) = error as? PolymarketAPIError else { return false }

        return statusCode == Constants.staleCursorStatusCode
    }

    @discardableResult
    func append(events newEvents: [PolymarketEvent]) -> Int {
        var known = Set(events.map(\.id))
        let fresh = newEvents.filter { known.insert($0.id).inserted }

        events.append(contentsOf: fresh)
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
        events = []
        eventCards = []
        cursor = nil
        hasNext = false
    }

    func snapshot() -> CategoryState {
        CategoryState(events: events, cursor: cursor, hasNext: hasNext)
    }

    func restore(_ state: CategoryState) {
        resetEvents()
        append(events: state.events)
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
        let events: [PolymarketEvent]
        let cursor: String?
        let hasNext: Bool
    }

    enum Constants {
        static let pageSize = 20
        static let staleCursorStatusCode = 502
        static let contentRefreshInterval: TimeInterval = 20
        static let silentRetryDelay: TimeInterval = 2
        static let maxEmptyPages = 3
    }
}
