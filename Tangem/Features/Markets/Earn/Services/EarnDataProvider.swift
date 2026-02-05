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

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

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
        _eventSubject.send(.loading)
        isLoading = true

        if lastFilter != filter {
            clearItems()
        }

        guard !isScheduledFetchPending else { return }

        lastFilter = filter

        taskCancellable?.cancel()
        taskCancellable = Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await loadItems(with: filter)
                handleFetchResult(.success(response))
            } catch {
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
            networkIds: filter.networkIds
        )

        return try await tangemApiService.loadEarnYieldMarkets(requestModel: requestModel)
    }

    private func handleFetchResult(_ result: Result<EarnDTO.List.Response, Error>) {
        do {
            let response = try result.get()

            let nextPage = response.meta.page + 1

            let metaHasNext = false
            hasNext = metaHasNext
            currentPage = nextPage

            isLoading = false
            hasLoadedItems = true

            let models = response.items.map { mapper.mapToEarnTokenModel(from: $0) }
            _eventSubject.send(.appendedItems(items: models, lastPage: !hasNext))
        } catch {
            isLoading = false

            if error.isCancellationError { return }

            AppLogger.tag("Earn").error(
                "Fetch failed (page \(currentPage))",
                error: error
            )
            _eventSubject.send(.failedToFetchData(error: error))

            if hasLoadedItems {
                scheduleRetryForFailedFetchRequest()
            }
        }
    }

    private func scheduleRetryForFailedFetchRequest() {
        guard !isScheduledFetchPending else { return }

        isScheduledFetchPending = true
        AppLogger.tag("Earn").debug("Retry scheduled in \(Int(repeatRequestDelayInSeconds))s")
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
