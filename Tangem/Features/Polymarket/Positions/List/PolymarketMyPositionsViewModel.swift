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

    private var loaded: [Row] = []
    private var seenIDs: Set<String> = []
    private var positionsGoneLocally: Set<String> = []
    private var offset = 0
    private var hasNext = false
    private var loadingTask: Task<Void, Never>?
    private var orderTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var pollingTask: Task<Void, Never>?
    private let appStateObserver = PolymarketAppStateObserver()
    private var bag: Set<AnyCancellable> = []

    init(
        tab: PolymarketPositionsTab,
        positionsService: PolymarketPositionsService,
        coordinator: PolymarketMyPositionsRoutable?
    ) {
        self.tab = tab
        self.positionsService = positionsService
        self.coordinator = coordinator

        reload()
        startRefreshing()
        bindApplicationState()
    }

    deinit {
        pollingTask?.cancel()
        refreshTask?.cancel()
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

    func refreshInPlace() {
        guard loadingState != .loading, loadingState != .paginationLoading else { return }

        let tab = tab

        refreshTask = runTask(in: self) { @MainActor viewModel in
            do {
                let page = try await viewModel.page(for: tab, offset: 0)
                try Task.checkCancellation()

                guard tab == viewModel.tab else { return }

                guard !viewModel.loaded.isEmpty else {
                    viewModel.offset = 0
                    viewModel.append(page)
                    viewModel.settle()
                    return
                }

                viewModel.replaceLoaded(with: page.rows)
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketLogger.error("Failed to refresh the positions list", error: error)
            }
        }
    }

    func refresh() async {
        guard loadingState != .loading, loadingState != .paginationLoading else { return }

        loadingTask?.cancel()

        let tab = tab

        refreshTask = runTask(in: self) { @MainActor viewModel in
            do {
                let page = try await viewModel.page(for: tab, offset: 0)
                try Task.checkCancellation()

                guard tab == viewModel.tab else { return }

                viewModel.loaded = []
                viewModel.seenIDs = []
                viewModel.offset = 0
                viewModel.append(page)
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
        loaded = []
        seenIDs = []
        rows = []
        offset = 0
        hasNext = false
        loadingState = .loading

        fetch()
    }

    // MARK: - View actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .closeTapped:
            loadingTask?.cancel()
            coordinator?.closeMyPositions()
        case .retryTapped:
            reload()
        case .filterSelected(let filter):
            guard self.filter != filter, canChangeFilter else { return }

            self.filter = filter
            applyFilter()
            continueAfterFilterChange()
        case .loadMore:
            loadMore()
        case .rowTapped(let id):
            openPosition(id: id)
        }
    }
}

// MARK: - Loading

private extension PolymarketMyPositionsViewModel {
    func loadMore() {
        guard hasNext, loadingState != .paginationLoading, loadingState != .loading else { return }

        loadingState = .paginationLoading
        fetch()
    }

    func fetch(attempt: Int = 0) {
        let tab = tab

        loadingTask = runTask(in: self) { @MainActor viewModel in
            do {
                let page = try await viewModel.page(for: tab, offset: viewModel.offset)
                try Task.checkCancellation()

                guard tab == viewModel.tab else { return }

                viewModel.append(page)

                if viewModel.rows.isEmpty, viewModel.hasNext, attempt < Constants.maxEmptyPages {
                    viewModel.fetch(attempt: attempt + 1)
                    return
                }

                viewModel.settle()
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketLogger.error("Failed to load the positions list", error: error)
                viewModel.loadingState = viewModel.loaded.isEmpty ? .error : .paginationError
            }
        }
    }

    func page(for tab: PolymarketPositionsTab, offset: Int) async throws -> Page {
        switch tab {
        case .active:
            let page = try await positionsService.openPositions(
                sort: .endDate,
                ascending: true,
                limit: Constants.pageSize,
                offset: offset
            )
            let rows = page.positions.filter { !$0.isEmptied && !positionsGoneLocally.contains($0.id) }.map(Row.open)

            return Page(rows: rows, receivedCount: page.receivedCount, hasNext: page.hasNext)
        case .finished:
            let page = try await positionsService.closedPositions(
                sort: .closedAt,
                ascending: false,
                limit: Constants.pageSize,
                offset: offset
            )
            return Page(rows: page.rows, receivedCount: page.receivedCount, hasNext: page.hasNext)
        }
    }

    func append(_ page: Page) {
        let fresh = page.rows.filter { seenIDs.insert($0.id).inserted }

        loaded.append(contentsOf: fresh)
        offset += page.receivedCount
        hasNext = page.hasNext || page.receivedCount == Constants.pageSize

        applyFilter()
    }

    func applyFilter() {
        rows = loaded.filter(filter.accepts).map(\.rowModel)
    }

    func replaceLoaded(with refreshed: [Row]) {
        let byID = Dictionary(refreshed.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        loaded = loaded.map { byID[$0.id] ?? $0 }

        applyFilter()
    }

    func bindApplicationState() {
        appStateObserver.start { [weak self] isInBackground in
            guard let self else { return }

            if isInBackground {
                stopRefreshing()
            } else {
                refreshInPlace()
                startRefreshing()
            }
        }
    }

    func stopRefreshing() {
        pollingTask?.cancel()
        pollingTask = nil
        refreshTask?.cancel()
    }

    func startRefreshing() {
        pollingTask?.cancel()

        pollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Constants.refreshInterval))

                guard !Task.isCancelled, let self else { return }

                refreshInPlace()
            }
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

// MARK: - Opening a row

extension PolymarketMyPositionsViewModel {
    func openPosition(id: String) {
        guard let row = loaded.first(where: { $0.id == id }) else { return }

        switch row {
        case .open(let position) where position.isRedeemable || position.settlement?.isResolved == true:
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
    enum Row {
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
        let receivedCount: Int
        let hasNext: Bool
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

private extension PolymarketClosedPositionsPage {
    var rows: [PolymarketMyPositionsViewModel.Row] {
        positions.map(PolymarketMyPositionsViewModel.Row.closed)
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
        case closeTapped
        case retryTapped
        case filterSelected(PolymarketPositionTypeFilter)
        case loadMore
        case rowTapped(String)
    }
}

// MARK: - Constants

private extension PolymarketMyPositionsViewModel {
    enum Constants {
        static let pageSize = 20
        static let maxEmptyPages = 3
        static let refreshInterval: TimeInterval = 20
    }
}
