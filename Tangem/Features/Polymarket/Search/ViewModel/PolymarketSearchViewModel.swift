//
//  PolymarketSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemPolymarket

final class PolymarketSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var eventCards: [PolymarketEventCard.Model] = []
    @Published private(set) var state: State = .prompt

    weak var coordinator: PolymarketSearchRoutable?

    private let apiProvider: PolymarketAPIProvider
    private let debounceInterval: DispatchQueue.SchedulerTimeType.Stride

    private var events: [PolymarketEvent] = []
    private var activeQuery = ""
    private var page = Constants.firstPage
    private var hasNext = false

    private var searchTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        apiProvider: PolymarketAPIProvider,
        debounceInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(Constants.debounceMilliseconds)
    ) {
        self.apiProvider = apiProvider
        self.debounceInterval = debounceInterval

        bind()
    }
}

// MARK: - Actions

extension PolymarketSearchViewModel {
    func loadMore() {
        guard hasNext, state != .paginationLoading, !activeQuery.isEmpty else { return }

        search(query: activeQuery, more: true)
    }

    func retry() {
        guard !activeQuery.isEmpty else { return }

        search(query: activeQuery)
    }

    func reset() {
        searchTask?.cancel()
        query = ""
        activeQuery = ""
        resetResults()
        state = .prompt
    }

    func openEventDetails(eventID: String) {
        coordinator?.openEventDetailsFromSearch(eventID: eventID)
    }
}

// MARK: - Query

private extension PolymarketSearchViewModel {
    func bind() {
        $query
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: debounceInterval, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, query in viewModel.handle(settled: query) }
            .store(in: &bag)
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

private extension PolymarketSearchViewModel {
    func search(query: String, more: Bool = false) {
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

                viewModel.apply(result: result, requestedPage: requestedPage)
            } catch {
                viewModel.handleFailure(error)
            }
        }
    }

    func apply(result: PolymarketSearchResult, requestedPage: Int) {
        page = result.page ?? requestedPage
        hasNext = result.hasNext

        var known = Set(events.map(\.id))
        let fresh = result.events.filter { known.insert($0.id).inserted }

        events.append(contentsOf: fresh)
        eventCards.append(contentsOf: fresh.map(makeCard))

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
            onSelectOutcome: { [weak self] _, _ in self?.openEventDetails(eventID: event.id) }
        )
    }
}

// MARK: - State

extension PolymarketSearchViewModel {
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

private extension PolymarketSearchViewModel {
    enum Constants {
        static let debounceMilliseconds = 500
        static let minQueryLength = 3
        static let pageSize = 20
        static let firstPage = 1
    }
}
