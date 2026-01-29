//
//  EarnDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

@MainActor
final class EarnDataProvider {
    // MARK: - Dependencies

    // [REDACTED_TODO_COMMENT]
    private var tangemApiService: TangemApiService = FakeTangemApiService()

    // MARK: - Subjects

    private let _eventSubject = PassthroughSubject<Event, Never>()

    var eventPublisher: AnyPublisher<Event, Never> {
        _eventSubject.eraseToAnyPublisher()
    }

    // MARK: - Public Properties

    var canFetchMore: Bool {
        !isLoading && hasNext
    }

    // MARK: - Private Properties

    private(set) var isLoading: Bool = false

    private var currentPage: Int = 1
    private var hasNext: Bool = true
    private var hasLoadedItems: Bool = false
    private var lastFilter: Filter?

    private let limitPerPage: Int
    private let repeatRequestDelayInSeconds: TimeInterval = 10
    private let mapper = EarnModelMapper()

    private var taskCancellable: AnyCancellable?
    private var scheduledFetchTask: AnyCancellable?
    private var isScheduledFetchPending: Bool = false

    // MARK: - Init

    init(limitPerPage: Int = 20) {
        self.limitPerPage = limitPerPage
    }

    // MARK: - Public Methods

    func reset() {
        lastFilter = nil
        clearItems()
        _eventSubject.send(.cleared)
        isLoading = false
    }

    func fetch(with filter: Filter) {
        AppLogger.tag("Earn").debug("fetch called with filter: type=\(filter.type), networkIds=\(String(describing: filter.networkIds))")

        _eventSubject.send(.loading)
        isLoading = true

        if lastFilter != filter {
            AppLogger.tag("Earn").debug("filter changed, clearing items")
            clearItems()
        }

        guard !isScheduledFetchPending else {
            AppLogger.tag("Earn").debug("scheduledFetchTask exists, skipping fetch")
            return
        }

        lastFilter = filter

        taskCancellable?.cancel()
        taskCancellable = Task { [weak self] in
            guard let self else { return }

            do {
                AppLogger.tag("Earn").debug("starting API request...")
                let response = try await loadItems(with: filter)
                AppLogger.tag("Earn").debug("API success, got \(response.items.count) items")
                handleFetchResult(.success(response))
            } catch {
                AppLogger.tag("Earn").debug("API error: \(error)")
                handleFetchResult(.failure(error))
            }
        }.eraseToAnyCancellable()
    }

    func fetchMore() {
        guard canFetchMore, let lastFilter else { return }
        fetch(with: lastFilter)
    }

    // MARK: - Private Methods

    private func clearItems() {
        currentPage = 1
        hasNext = true
        hasLoadedItems = false

        if scheduledFetchTask != nil {
            scheduledFetchTask?.cancel()
            scheduledFetchTask = nil
            isScheduledFetchPending = false
        }

        _eventSubject.send(.startInitialFetch)
    }

    private func loadItems(with filter: Filter) async throws -> EarnDTO.List.Response {
        let requestModel = EarnDTO.List.Request(
            isForEarn: true,
            page: currentPage,
            limit: limitPerPage,
            type: filter.type.apiValue,
            network: filter.networkIds
        )

        AppLogger.tag("Earn").debug("Loading earn list with request page=\(currentPage), limit=\(limitPerPage)")

        return try await tangemApiService.loadEarnYieldMarkets(requestModel: requestModel)
    }

    private func handleFetchResult(_ result: Result<EarnDTO.List.Response, Error>) {
        AppLogger.tag("Earn").debug("handleFetchResult called")

        do {
            let response = try result.get()

            let nextPage = response.meta.page + 1
//            let metaHasNext = response.meta.hasNext
            let metaHasNext = false
            hasNext = metaHasNext
            currentPage = nextPage

            isLoading = false
            hasLoadedItems = true

            let models = response.items.map { mapper.mapToEarnTokenModel(from: $0) }
            AppLogger.tag("Earn").debug("sending .appendedItems with \(models.count) items")
            _eventSubject.send(.appendedItems(items: models, lastPage: !hasNext))
        } catch {
            isLoading = false

            if error.isCancellationError {
                AppLogger.tag("Earn").debug("Request was cancelled")
                return
            }

            AppLogger.tag("Earn").error("Failed to fetch earn list", error: error)
            _eventSubject.send(.failedToFetchData(error: error))

            if hasLoadedItems {
                scheduleRetryForFailedFetchRequest()
            }
        }
    }

    private func scheduleRetryForFailedFetchRequest() {
        guard !isScheduledFetchPending else { return }

        isScheduledFetchPending = true
        scheduledFetchTask = Task.delayed(withDelay: repeatRequestDelayInSeconds, operation: { @MainActor [weak self] in
            guard let self else { return }

            isScheduledFetchPending = false
            scheduledFetchTask = nil
            fetchMore()
        }).eraseToAnyCancellable()
    }
}

// MARK: - Event

extension EarnDataProvider {
    enum Event: Equatable {
        case loading
        case idle
        case failedToFetchData(error: Error)
        case appendedItems(items: [EarnTokenModel], lastPage: Bool)
        case startInitialFetch
        case cleared

        static func == (lhs: Event, rhs: Event) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading),
                 (.idle, .idle),
                 (.startInitialFetch, .startInitialFetch),
                 (.cleared, .cleared),
                 (.failedToFetchData, .failedToFetchData):
                return true
            case (.appendedItems(let items1, let lastPage1), .appendedItems(let items2, let lastPage2)):
                return items1.map(\.id) == items2.map(\.id) && lastPage1 == lastPage2
            default:
                return false
            }
        }
    }
}
