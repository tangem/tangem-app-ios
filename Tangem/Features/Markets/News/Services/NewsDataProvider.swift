//
//  NewsDataProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

@MainActor
final class NewsDataProvider {
    // MARK: - Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Subjects

    private let _categoriesSubject = CurrentValueSubject<[NewsDTO.Categories.Item], Never>([])
    private let _eventSubject = PassthroughSubject<Event, Never>()

    var categoriesPublisher: AnyPublisher<[NewsDTO.Categories.Item], Never> {
        _categoriesSubject.eraseToAnyPublisher()
    }

    var eventPublisher: AnyPublisher<Event, Never> {
        _eventSubject.eraseToAnyPublisher()
    }

    var categories: [NewsDTO.Categories.Item] {
        _categoriesSubject.value
    }

    // MARK: - Public Properties

    var canFetchMore: Bool {
        !isLoading && hasNext
    }

    // MARK: - Private Properties

    private(set) var isLoading: Bool = false

    private var currentPage: Int = 1
    private var currentAsOf: String?
    private var hasNext: Bool = true
    private var hasLoadedItems: Bool = false
    private var lastCategoryIds: [Int]?

    private let limitPerPage: Int
    private let repeatRequestDelayInSeconds: TimeInterval = 10

    private var taskCancellable: AnyCancellable?
    private var categoriesCancellable: AnyCancellable?
    private var scheduledFetchTask: AnyCancellable?

    // MARK: - Init

    init(limitPerPage: Int = 20) {
        self.limitPerPage = limitPerPage
    }

    // MARK: - Public Methods

    func reset() {
        lastCategoryIds = nil
        clearItems()

        _eventSubject.send(.cleared)
        isLoading = false
    }

    func fetch(categoryIds: [Int]? = nil) {
        AppLogger.debug("📰 [NewsDataProvider] fetch called with categoryIds: \(String(describing: categoryIds))")

        _eventSubject.send(.loading)
        isLoading = true

        if lastCategoryIds != categoryIds {
            AppLogger.debug("📰 [NewsDataProvider] categoryIds changed, clearing items")
            clearItems()
        }

        guard scheduledFetchTask == nil else {
            AppLogger.debug("📰 [NewsDataProvider] scheduledFetchTask exists, skipping fetch")
            return
        }

        lastCategoryIds = categoryIds

        taskCancellable?.cancel()
        taskCancellable = Task { [weak self] in
            guard let self else { return }

            do {
                AppLogger.debug("📰 [NewsDataProvider] starting API request...")
                let response = try await loadItems(categoryIds: categoryIds)
                AppLogger.debug("📰 [NewsDataProvider] API success, got \(response.items.count) items")
                handleFetchResult(.success(response))
            } catch {
                AppLogger.debug("📰 [NewsDataProvider] API error: \(error)")
                handleFetchResult(.failure(error))
            }
        }.eraseToAnyCancellable()
    }

    func fetchMore() {
        guard canFetchMore else { return }
        fetch(categoryIds: lastCategoryIds)
    }

    func fetchCategories() {
        categoriesCancellable?.cancel()
        categoriesCancellable = Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await tangemApiService.loadNewsCategories()
                _categoriesSubject.send(response.items)
            } catch {
                // Silently fail - categories are optional
            }
        }.eraseToAnyCancellable()
    }

    // MARK: - Private Methods

    private func clearItems() {
        currentPage = 1
        currentAsOf = nil
        hasNext = true
        hasLoadedItems = false

        if scheduledFetchTask != nil {
            scheduledFetchTask?.cancel()
            scheduledFetchTask = nil
        }

        _eventSubject.send(.startInitialFetch)
    }

    private func loadItems(categoryIds: [Int]?) async throws -> NewsDTO.List.Response {
        let requestModel = NewsDTO.List.Request(
            page: currentPage,
            limit: limitPerPage,
            lang: Locale.current.language.languageCode?.identifier,
            asOf: currentAsOf,
            categoryIds: categoryIds
        )

        return try await tangemApiService.loadNewsList(requestModel: requestModel)
    }

    private func handleFetchResult(_ result: Result<NewsDTO.List.Response, Error>) {
        AppLogger.debug("📰 [NewsDataProvider] handleFetchResult called")

        do {
            let response = try result.get()

            AppLogger.debug("📰 [NewsDataProvider] response meta - page: \(response.meta.page), hasNext: \(response.meta.hasNext), total: \(response.meta.total)")

            currentPage = response.meta.page + 1
            hasNext = response.meta.hasNext

            // Store asOf from first request to keep pagination stable
            if currentAsOf == nil {
                currentAsOf = response.meta.asOf
            }

            isLoading = false
            hasLoadedItems = true

            AppLogger.debug("📰 [NewsDataProvider] sending .appendedItems event with \(response.items.count) items")
            _eventSubject.send(.appendedItems(items: response.items, lastPage: !response.meta.hasNext))
        } catch {
            // Always set isLoading to false - retry will set it back to true when calling fetch()
            isLoading = false

            if error.isCancellationError {
                return
            }

            _eventSubject.send(.failedToFetchData(error: error))

            if hasLoadedItems {
                scheduleRetryForFailedFetchRequest()
            }
        }
    }

    private func scheduleRetryForFailedFetchRequest() {
        guard scheduledFetchTask == nil else { return }

        scheduledFetchTask = Task.delayed(withDelay: repeatRequestDelayInSeconds, operation: { @MainActor [weak self] in
            guard let self else { return }

            scheduledFetchTask = nil
            fetchMore()
        }).eraseToAnyCancellable()
    }
}

// MARK: - Event

extension NewsDataProvider {
    enum Event: Equatable {
        case loading
        case idle
        case failedToFetchData(error: Error)
        case appendedItems(items: [NewsDTO.List.Item], lastPage: Bool)
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
