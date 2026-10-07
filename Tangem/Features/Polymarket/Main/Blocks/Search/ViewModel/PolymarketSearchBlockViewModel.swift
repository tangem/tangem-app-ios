//
//  PolymarketSearchBlockViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import TangemFoundation
import TangemPolymarket
import TangemPolymarketUI

final class PolymarketSearchBlockViewModel: ObservableObject {
    @Published var query = ""
    @Published var isFieldActive = false {
        didSet {
            if isFieldActive {
                isSearching = true
            }
        }
    }

    @Published private(set) var isSearching = false
    @Published private(set) var eventCards: [PolymarketEventCard.Model] = []
    @Published private(set) var state: State = .prompt

    private let apiProvider: PolymarketAPIProvider
    private let activityHandler: PolymarketMainActivityHandler
    private let isRegionRestricted: () -> Bool
    private let debounceInterval: DispatchQueue.SchedulerTimeType.Stride
    private weak var routable: PolymarketSearchBlockRoutable?

    private var events: [PolymarketEvent] = []
    private var activeQuery = ""
    private var page = Constants.firstPage
    private var hasNext = false

    private var searchTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var visibleResultsRefreshTask: Task<Void, Never>?
    private let appStateObserver = AppStateObserver()
    private var bag: Set<AnyCancellable> = []

    init(
        apiProvider: PolymarketAPIProvider,
        activityHandler: PolymarketMainActivityHandler,
        isRegionRestricted: @escaping () -> Bool,
        routable: PolymarketSearchBlockRoutable,
        debounceInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(Constants.debounceMilliseconds)
    ) {
        self.apiProvider = apiProvider
        self.activityHandler = activityHandler
        self.isRegionRestricted = isRegionRestricted
        self.routable = routable
        self.debounceInterval = debounceInterval

        bind()
        startRefreshing()
    }

    deinit {
        refreshTask?.cancel()
        visibleResultsRefreshTask?.cancel()
    }
}

// MARK: - View actions

extension PolymarketSearchBlockViewModel {
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .clearQuery:
            query = ""
        case .cancel:
            exitSearch()
        case .openEventDetails(let id):
            openEventDetails(eventID: id)
        case .retry:
            retry()
        case .loadNextPage, .retryNextPage:
            loadMore()
        }
    }

    enum ViewAction {
        case clearQuery
        case cancel
        case openEventDetails(id: String)
        case retry
        case loadNextPage
        case retryNextPage
    }
}

// MARK: - Actions

private extension PolymarketSearchBlockViewModel {
    func exitSearch() {
        searchTask?.cancel()
        isSearching = false
        isFieldActive = false
        query = ""
        activeQuery = ""
        resetResults()
        state = .prompt
    }

    func loadMore() {
        guard hasNext, state != .paginationLoading, !activeQuery.isEmpty else { return }

        search(query: activeQuery, more: true)
    }

    func retry() {
        guard !activeQuery.isEmpty else { return }

        search(query: activeQuery)
    }

    func openEventDetails(eventID: String) {
        isFieldActive = false

        let activityHandler = activityHandler

        routable?.openEventDetails(
            eventID: eventID,
            category: nil,
            onOrderPlaced: { [weak activityHandler] indexing in activityHandler?.orderPlaced(awaiting: indexing) }
        )
    }

    func openOrder(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String) {
        isFieldActive = false

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

// MARK: - Query

private extension PolymarketSearchBlockViewModel {
    func bind() {
        $query
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: debounceInterval, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, query in viewModel.handle(settled: query) }
            .store(in: &bag)

        appStateObserver.start { [weak self] isInBackground in
            guard let self else { return }

            if isInBackground {
                stopRefreshing()
            } else {
                refreshVisibleResults()
                startRefreshing()
            }
        }
    }

    func handle(settled query: String) {
        guard query.count >= Constants.minQueryLength else {
            searchTask?.cancel()
            resetResults()
            activeQuery = ""
            state = .prompt

            return
        }

        search(query: query)
    }
}

// MARK: - Search

private extension PolymarketSearchBlockViewModel {
    func search(query: String, more: Bool = false, emptyPages: Int = 0) {
        searchTask?.cancel()

        if !more {
            resetResults()
        }

        activeQuery = query
        state = events.isEmpty ? .loading : .paginationLoading

        let requestedPage = more ? page + 1 : Constants.firstPage

        searchTask = runTask(in: self) { @MainActor viewModel in
            do {
                let result = try await viewModel.apiProvider.search(
                    request: PolymarketSearchRequest(query: query, limit: Constants.pageSize, page: requestedPage)
                )
                try Task.checkCancellation()

                viewModel.apply(result: result, requestedPage: requestedPage, emptyPages: emptyPages)
            } catch {
                viewModel.handleFailure(error)
            }
        }
    }

    func startRefreshing() {
        refreshTask?.cancel()

        refreshTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Constants.refreshInterval))

                guard !Task.isCancelled, let self else { return }

                refreshVisibleResults()
            }
        }
    }

    func stopRefreshing() {
        refreshTask?.cancel()
        refreshTask = nil
        visibleResultsRefreshTask?.cancel()
        visibleResultsRefreshTask = nil
    }

    func refreshVisibleResults() {
        guard events.isNotEmpty, !activeQuery.isEmpty, state != .loading, state != .paginationLoading else { return }

        let query = activeQuery

        visibleResultsRefreshTask?.cancel()
        visibleResultsRefreshTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let result = try await apiProvider.search(
                    request: PolymarketSearchRequest(query: query, limit: Constants.pageSize, page: Constants.firstPage)
                )
                try Task.checkCancellation()

                guard query == activeQuery else { return }

                replaceVisibleResults(with: result.events)
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketLogger.error("Failed to refresh the search results", error: error)
            }
        }
    }

    func replaceVisibleResults(with refreshed: [PolymarketEvent]) {
        let byID = Dictionary(refreshed.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        events = events.map { byID[$0.id] ?? $0 }
        eventCards = events.map(makeCard)
    }

    func apply(result: PolymarketSearchResult, requestedPage: Int, emptyPages: Int) {
        page = result.page ?? requestedPage
        hasNext = result.hasNext

        var known = Set(events.map(\.id))
        let fresh = result.events.filter { known.insert($0.id).inserted }

        events.append(contentsOf: fresh)
        eventCards.append(contentsOf: fresh.map(makeCard))

        guard fresh.isNotEmpty || !hasNext || emptyPages >= Constants.maxEmptyPages else {
            search(query: activeQuery, more: true, emptyPages: emptyPages + 1)
            return
        }

        state = events.isEmpty ? .noResults : (hasNext ? .loaded : .allDataLoaded)
    }

    func handleFailure(_ error: Error) {
        guard !error.isCancellationError else { return }

        state = events.isEmpty ? .error : .paginationError
    }

    func resetResults() {
        events = []
        eventCards = []
        page = Constants.firstPage
        hasNext = false
    }

    func makeCard(for event: PolymarketEvent) -> PolymarketEventCard.Model {
        .make(
            event: event,
            category: nil,
            isInActivePredicts: false,
            onSelectOutcome: { [weak self] market, outcome in
                self?.openOrder(market: market, outcome: outcome, eventTitle: event.title)
            }
        )
    }
}

// MARK: - State

extension PolymarketSearchBlockViewModel {
    enum State: Equatable {
        case prompt
        case loading
        case loaded
        case allDataLoaded
        case noResults
        case error
        case paginationLoading
        case paginationError
    }
}

// MARK: - Constants

private extension PolymarketSearchBlockViewModel {
    enum Constants {
        static let debounceMilliseconds = 500
        static let minQueryLength = 3
        static let pageSize = 20
        static let refreshInterval: TimeInterval = 20
        static let maxEmptyPages = 3
        static let firstPage = 1
    }
}
