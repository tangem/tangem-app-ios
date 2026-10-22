//
//  PolymarketMyPositionsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI

@MainActor
final class PolymarketMyPositionsViewModel: ObservableObject, Identifiable {
    @Published var finishedPosition: PolymarketFinishedPositionSheetView.Model?
    @Published private(set) var rows: [PolymarketPositionRow.Model] = []
    @Published private(set) var loadingState: LoadingState = .loading
    @Published private(set) var filter: PolymarketPositionTypeFilter = .all

    @Published var tab: PolymarketPositionsTab {
        didSet {
            guard tab != oldValue else { return }

            filter = .all
            reload()
        }
    }

    let tabs = PolymarketPositionsTab.allCases

    var filters: [PolymarketPositionTypeFilter] { PolymarketPositionTypeFilter.cases(for: tab) }

    var emptyMessage: String {
        filter == .all ? tab.emptyMessage : Localization.predictionSearchEmptyTitle
    }

    private let positionsService: PolymarketPositionsService
    private weak var coordinator: PolymarketMyPositionsRoutable?
    private let now: () -> Date
    private let visibilitySettleDelay: TimeInterval
    private let poller: PolymarketForegroundPoller

    private var feed = PolymarketPagedFeed<Row>()
    private var cursor: String?
    private var positionsGoneLocally: Set<String> = []
    private var visibleRowIDs: Set<String> = []
    private var refreshingPages: Set<PageKey> = []
    private var rejectedPages: Set<PageKey> = []
    private var loadingTask: Task<Void, Never>?
    private var orderTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var visibilityTask: Task<Void, Never>?
    private var isPollingPaused = false
    private var hasVisibilityChangedDuringTick = false

    init(
        tab: PolymarketPositionsTab,
        positionsService: PolymarketPositionsService,
        coordinator: PolymarketMyPositionsRoutable?,
        notificationCenter: NotificationCenter = .default,
        now: @escaping () -> Date = Date.init,
        visibilitySettleDelay: TimeInterval? = nil
    ) {
        self.tab = tab
        self.positionsService = positionsService
        self.coordinator = coordinator
        self.now = now
        self.visibilitySettleDelay = visibilitySettleDelay ?? Constants.visibilitySettleDelay
        poller = PolymarketForegroundPoller(interval: Constants.pollInterval, notificationCenter: notificationCenter)

        reload()

        poller.start(
            onTick: { [weak self] in await self?.pollVisiblePages() },
            onPause: { [weak self] in self?.pausePolling() }
        )
    }

    deinit {
        loadingTask?.cancel()
        refreshTask?.cancel()
        visibilityTask?.cancel()
    }

    func orderPlaced(awaiting indexing: PolymarketOrderIndexing) {
        orderTask?.cancel()

        orderTask = runTask(in: self) { viewModel in
            _ = await indexing.value

            guard !Task.isCancelled else { return }

            viewModel.reload()
        }
    }

    func claimed(_ position: PolymarketPosition?) {
        if let position {
            positionsGoneLocally.insert(position.id)
        }

        reload()
    }

    func refresh() async {
        guard loadingState != .loading, loadingState != .paginationLoading else { return }

        loadingTask?.cancel()

        let tab = tab

        refreshTask = runTask(in: self) { @MainActor viewModel in
            do {
                let page = try await viewModel.page(for: tab, cursor: nil)
                try Task.checkCancellation()

                guard tab == viewModel.tab else { return }

                viewModel.resetFeed()
                viewModel.append(page, requestCursor: nil)
                viewModel.settle()
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketLogger.error("Failed to refresh the positions list", error: error)
            }
        }

        await refreshTask?.value
    }

    func reload() {
        loadingTask?.cancel()
        refreshTask?.cancel()
        resetFeed()
        rows = []
        loadingState = .loading

        fetch()
    }

    // MARK: - View actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .close:
            loadingTask?.cancel()
            coordinator?.closeMyPositions()
        case .retry:
            reload()
        case .selectFilter(let filter):
            guard self.filter != filter, canChangeFilter else { return }

            self.filter = filter
            applyFilter()
            continueAfterFilterChange()
        case .loadNextPage, .retryNextPage:
            loadMore()
        case .openPositionDetails(let id):
            openPosition(id: id)
        case .onRowVisibilityChange(let id, let isVisible):
            updateVisibility(rowID: id, isVisible: isVisible)
        }
    }
}

// MARK: - Loading

private extension PolymarketMyPositionsViewModel {
    var hasNext: Bool {
        cursor != nil
    }

    func loadMore() {
        guard hasNext, loadingState != .paginationLoading, loadingState != .loading else { return }

        loadingState = .paginationLoading
        fetch()
    }

    func fetch(attempt: Int = 0) {
        let tab = tab
        let requestCursor = cursor
        let generation = feed.generation

        loadingTask = runTask(in: self) { @MainActor viewModel in
            do {
                let page = try await viewModel.page(for: tab, cursor: requestCursor)
                try Task.checkCancellation()

                guard tab == viewModel.tab, generation == viewModel.feed.generation else { return }

                viewModel.append(page, requestCursor: requestCursor)

                if viewModel.rows.isEmpty, viewModel.hasNext, attempt < Constants.maxEmptyPages {
                    viewModel.fetch(attempt: attempt + 1)
                    return
                }

                viewModel.settle()
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketLogger.error("Failed to load the positions list", error: error)

                if requestCursor != nil, Self.isRejectedCursor(error) {
                    viewModel.reload()
                    return
                }

                viewModel.loadingState = viewModel.feed.isEmpty ? .error : .paginationError
            }
        }
    }

    func page(for tab: PolymarketPositionsTab, cursor: String?) async throws -> Page {
        switch tab {
        case .active:
            let page = try await positionsService.openPositions(limit: Constants.pageSize, cursor: cursor)

            return Page(rows: page.positions.map(Row.open), nextCursor: page.nextCursor)
        case .finished:
            let page = try await positionsService.closedPositions(limit: Constants.pageSize, cursor: cursor)

            return Page(rows: page.positions.map(Row.closed), nextCursor: page.nextCursor)
        }
    }

    static func isRejectedCursor(_ error: Error) -> Bool {
        guard case .http(let statusCode, _) = error as? PolymarketAPIError else { return false }

        return statusCode == Constants.badRequestStatusCode
    }

    func append(_ page: Page, requestCursor: String?) {
        feed.append(page.rows, requestCursor: requestCursor, at: now())
        cursor = page.nextCursor

        applyFilter()
    }

    func resetFeed() {
        feed.removeAll()
        cursor = nil
        refreshingPages = []
        rejectedPages = []
        visibilityTask?.cancel()
        visibilityTask = nil
        hasVisibilityChangedDuringTick = false
    }

    func applyFilter() {
        rows = feed.items.filter { isShown($0) && filter.accepts($0) }.map(\.rowModel)
    }

    func isShown(_ row: Row) -> Bool {
        switch row {
        case .open(let position): !position.isEmptied && !positionsGoneLocally.contains(position.id)
        case .closed: true
        }
    }

    var canChangeFilter: Bool {
        switch loadingState {
        case .loaded, .allDataLoaded, .empty, .paginationError: true
        case .loading, .paginationLoading, .error: false
        }
    }

    func continueAfterFilterChange() {
        guard rows.isEmpty, hasNext else {
            settle()
            return
        }

        loadingState = .paginationLoading
        fetch()
    }

    func settle() {
        if hasNext {
            loadingState = .loaded
        } else {
            loadingState = rows.isEmpty ? .empty : .allDataLoaded
        }
    }
}

// MARK: - Polling

private extension PolymarketMyPositionsViewModel {
    func pollVisiblePages() async {
        isPollingPaused = false

        guard !feed.isEmpty else {
            if loadingState == .empty {
                await refresh()
            }

            return
        }

        await refreshVisiblePages()
    }

    func pausePolling() {
        isPollingPaused = true
        visibilityTask?.cancel()
        visibilityTask = nil
        hasVisibilityChangedDuringTick = false
    }

    func updateVisibility(rowID: String, isVisible: Bool) {
        guard isVisible else {
            visibleRowIDs.remove(rowID)
            return
        }

        visibleRowIDs.insert(rowID)

        guard visibilityTask == nil else {
            hasVisibilityChangedDuringTick = true
            return
        }

        scheduleVisibilityTick()
    }

    func scheduleVisibilityTick() {
        guard !isPollingPaused, visibilityTask == nil else { return }

        visibilityTask = runTask(in: self) { @MainActor viewModel in
            try? await Task.sleep(for: .seconds(viewModel.visibilitySettleDelay))

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

    func refreshVisiblePages() async {
        let stalePageIDs = feed.stalePageIDs(
            showing: visibleRowIDs,
            now: now(),
            staleAfter: Constants.staleAfter,
            minimumInterval: Constants.pollInterval
        )

        let generation = feed.generation

        for pageID in stalePageIDs where !rejectedPages.contains(PageKey(generation: generation, pageID: pageID)) {
            guard generation == feed.generation else { return }

            await refresh(pageID: pageID)
        }
    }

    func refresh(pageID: Int) async {
        let key = PageKey(generation: feed.generation, pageID: pageID)

        guard let page = feed.page(id: pageID), refreshingPages.insert(key).inserted else { return }

        defer { refreshingPages.remove(key) }

        let tab = tab
        feed.markAttempt(pageID: pageID, at: now())

        do {
            let refreshed = try await self.page(for: tab, cursor: page.requestCursor)
            try Task.checkCancellation()

            guard key.generation == feed.generation, tab == self.tab, feed.merge(refreshed.rows, into: pageID, at: now()) > 0 else {
                return
            }

            applyFilter()
        } catch {
            guard !error.isCancellationError, key.generation == feed.generation else { return }

            PolymarketLogger.error("Failed to refresh a page of the positions list", error: error)

            if page.requestCursor != nil, Self.isRejectedCursor(error) {
                rejectedPages.insert(key)
                return
            }

            feed.markFailure(pageID: pageID)
        }
    }
}

// MARK: - Opening a row

extension PolymarketMyPositionsViewModel {
    func openPosition(id: String) {
        guard let row = feed.items.first(where: { $0.id == id }) else { return }

        switch row {
        case .open(let position) where position.opensClaim:
            coordinator?.openRedeem(position: position, onClaimed: { [weak self] claimed in self?.claimed(claimed) })
        case .open(let position):
            coordinator?.openPositionDetails(
                position: position,
                onOrderPlaced: { [weak self] indexing in self?.orderPlaced(awaiting: indexing) }
            )
        case .closed(let position): finishedPosition = .make(closedPosition: position)
        }
    }
}

// MARK: - Row

private extension PolymarketMyPositionsViewModel {
    enum Row: Identifiable {
        case open(PolymarketPosition)
        case closed(PolymarketClosedPosition)

        var id: String {
            switch self {
            case .open(let position): position.id
            case .closed(let position): position.id
            }
        }

        var rowModel: PolymarketPositionRow.Model {
            switch self {
            case .open(let position): .make(position: position)
            case .closed(let position): .make(closedPosition: position)
            }
        }
    }

    struct Page {
        let rows: [Row]
        let nextCursor: String?
    }

    struct PageKey: Hashable {
        let generation: UUID
        let pageID: Int
    }
}

private extension PolymarketPositionTypeFilter {
    func accepts(_ row: PolymarketMyPositionsViewModel.Row) -> Bool {
        switch row {
        case .open(let position): accepts(position)
        case .closed(let position): accepts(position)
        }
    }
}

// MARK: - State

extension PolymarketMyPositionsViewModel {
    enum LoadingState: Equatable {
        case loading
        case empty
        case error
        case loaded
        case allDataLoaded
        case paginationLoading
        case paginationError
    }

    enum ViewAction {
        case close
        case retry
        case selectFilter(PolymarketPositionTypeFilter)
        case loadNextPage
        case retryNextPage
        case openPositionDetails(id: String)
        case onRowVisibilityChange(id: String, isVisible: Bool)
    }
}

// MARK: - Constants

private extension PolymarketMyPositionsViewModel {
    enum Constants {
        static let pageSize = 20
        static let maxEmptyPages = 3
        static let pollInterval: TimeInterval = 20
        static let staleAfter: TimeInterval = 20
        static let visibilitySettleDelay: TimeInterval = 0.5
        static let badRequestStatusCode = 400
    }
}
