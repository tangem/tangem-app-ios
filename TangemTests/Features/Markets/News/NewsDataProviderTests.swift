//
//  NewsDataProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Combine
import Testing
@testable import Tangem

@MainActor
@Suite("NewsDataProvider Tests", .tags(.news))
struct NewsDataProviderTests {
    @Test("Fetch emits loading and appended items")
    func fetchEmitsLoadingAndAppendedItems() async throws {
        let response = Self.makeResponse(ids: [1, 2], hasNext: false)
        let apiService = FakeTangemApiService()
        apiService.loadNewsListHandler = { _ in response }

        let provider = NewsDataProvider(limitPerPage: 2)
        try await Self.withInjected(apiService) {
            let events = await Self.collectEvents(from: provider, count: 2) {
                provider.fetch()
            }

            #expect(events.count == 2)
            #expect(events[0] == .loading)

            guard case .appendedItems(let items, let lastPage) = events[1] else {
                Issue.record("Expected appended items event")
                return
            }

            #expect(items.map(\.id) == [1, 2])
            #expect(lastPage == true)
        }
    }

    @Test("canFetchMore follows hasNext", arguments: Self.hasNextCases())
    func canFetchMoreFollowsHasNext(hasNext: Bool) async throws {
        let response = Self.makeResponse(ids: [1], hasNext: hasNext)
        let apiService = FakeTangemApiService()
        apiService.loadNewsListHandler = { _ in response }

        let provider = NewsDataProvider(limitPerPage: 1)
        try await Self.withInjected(apiService) {
            _ = await Self.collectEvents(from: provider, count: 2) {
                provider.fetch()
            }

            #expect(provider.canFetchMore == hasNext)
        }
    }

    @Test("Category change triggers startInitialFetch")
    func categoryChangeTriggersStartInitialFetch() async throws {
        let responses = [
            Self.makeResponse(ids: [1], hasNext: false, asOf: "a"),
            Self.makeResponse(ids: [2], hasNext: false, asOf: "b"),
        ]
        var responseIndex = 0
        let apiService = FakeTangemApiService()
        apiService.loadNewsListHandler = { _ in
            defer { responseIndex += 1 }
            return responses[responseIndex]
        }

        let provider = NewsDataProvider(limitPerPage: 1)
        try await Self.withInjected(apiService) {
            _ = await Self.collectEvents(from: provider, count: 2) {
                provider.fetch(categoryIds: [1])
            }

            let events = await Self.collectEvents(from: provider, count: 3) {
                provider.fetch(categoryIds: [2])
            }

            #expect(events.contains(.startInitialFetch))
        }
    }

    @Test("Reset clears state and emits cleared")
    func resetClearsStateAndEmitsCleared() async throws {
        let apiService = FakeTangemApiService()
        let provider = NewsDataProvider(limitPerPage: 1)

        try await Self.withInjected(apiService) {
            let events = await Self.collectEvents(from: provider, count: 2) {
                provider.reset()
            }

            #expect(events.contains(.startInitialFetch))
            #expect(events.contains(.cleared))
            #expect(provider.canFetchMore == true)
        }
    }

    @Test("fetchCategories publishes categories")
    func fetchCategoriesPublishesCategories() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsCategoriesHandler = {
            NewsDTO.Categories.Response(items: [
                NewsDTO.Categories.Item(id: 1, name: "Markets"),
                NewsDTO.Categories.Item(id: 2, name: "Regulation"),
            ])
        }

        let provider = NewsDataProvider(limitPerPage: 1)
        try await Self.withInjected(apiService) {
            let categories = await Self.collectCategories(from: provider) {
                provider.fetchCategories()
            }

            #expect(categories.map(\.id) == [1, 2])
            #expect(categories.map(\.name) == ["Markets", "Regulation"])
        }
    }

    @Test("Failed fetch after loaded data schedules automatic retry")
    func failedFetchAfterLoadedDataSchedulesAutomaticRetry() async throws {
        let attemptsCounter = AttemptsCounter()
        let apiService = FakeTangemApiService()
        apiService.loadNewsListHandler = { _ in
            let attempt = await attemptsCounter.increment()
            switch attempt {
            case 1:
                return Self.makeResponse(ids: [1], hasNext: true, asOf: "a")
            case 2:
                throw TestError.sample
            default:
                return Self.makeResponse(ids: [2], hasNext: false, asOf: "a")
            }
        }

        let provider = NewsDataProvider(limitPerPage: 1, repeatRequestDelayInSeconds: 0.05)

        try await Self.withInjected(apiService) {
            _ = await Self.collectEvents(from: provider, count: 2) {
                provider.fetch()
            }

            var events: [NewsDataProvider.Event] = []
            let cancellable = provider.eventPublisher.sink { events.append($0) }
            defer { _ = cancellable }

            provider.fetchMore()

            let didFailAndRecover = await Self.waitUntil {
                let hasFailure = events.contains {
                    if case .failedToFetchData = $0 {
                        return true
                    }
                    return false
                }
                let hasRecoveredAppend = events.contains {
                    if case .appendedItems(let items, _) = $0 {
                        return items.map(\.id) == [2]
                    }
                    return false
                }
                return hasFailure && hasRecoveredAppend
            }

            #expect(didFailAndRecover)
            #expect(provider.canFetchMore == false)
        }
    }

    @Test("Initial fetch failure does not schedule retry")
    func initialFetchFailureDoesNotScheduleRetry() async throws {
        let attemptsCounter = AttemptsCounter()
        let apiService = FakeTangemApiService()
        apiService.loadNewsListHandler = { _ in
            _ = await attemptsCounter.increment()
            throw TestError.sample
        }

        let provider = NewsDataProvider(limitPerPage: 1, repeatRequestDelayInSeconds: 0.02)

        try await Self.withInjected(apiService) {
            var events: [NewsDataProvider.Event] = []
            let cancellable = provider.eventPublisher.sink { events.append($0) }
            defer { _ = cancellable }

            provider.fetch()

            let didFail = await Self.waitUntil {
                events.contains {
                    if case .failedToFetchData = $0 {
                        return true
                    }
                    return false
                }
            }
            #expect(didFail)

            try? await Task.sleep(nanoseconds: 200_000_000)
            #expect(await attemptsCounter.value() == 1)
        }
    }
}

private extension NewsDataProviderTests {
    static func makeResponse(
        ids: [Int],
        hasNext: Bool,
        asOf: String = ""
    ) -> NewsDTO.List.Response {
        NewsDTO.List.Response(
            meta: NewsDTO.List.Meta(page: 1, limit: ids.count, total: ids.count, hasNext: hasNext, asOf: asOf),
            items: ids.map { Self.makeListItem(id: $0) }
        )
    }

    static func makeListItem(id: Int) -> NewsDTO.List.Item {
        NewsDTO.List.Item(
            id: id,
            createdAt: Date(),
            score: 1.0,
            language: "en",
            isTrending: false,
            categories: [],
            relatedTokens: [],
            title: "Title \(id)",
            newsUrl: "https://example.com/\(id)"
        )
    }

    nonisolated static func hasNextCases() -> [Bool] {
        [true, false]
    }

    static func withInjected(_ service: TangemApiService, operation: () async throws -> Void) async throws {
        try await NewsTestsDependencyIsolation.shared.run {
            let previous = InjectedValues[\.tangemApiService]
            InjectedValues[\.tangemApiService] = service
            defer { InjectedValues[\.tangemApiService] = previous }
            try await operation()
        }
    }

    static func collectEvents(
        from provider: NewsDataProvider,
        count: Int,
        action: () -> Void
    ) async -> [NewsDataProvider.Event] {
        await withCheckedContinuation { continuation in
            var events: [NewsDataProvider.Event] = []
            var cancellable: AnyCancellable?

            cancellable = provider.eventPublisher
                .sink { event in
                    events.append(event)
                    if events.count == count {
                        cancellable?.cancel()
                        continuation.resume(returning: events)
                    }
                }

            action()
        }
    }

    static func collectCategories(
        from provider: NewsDataProvider,
        action: () -> Void
    ) async -> [NewsDTO.Categories.Item] {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = provider.categoriesPublisher
                .dropFirst()
                .sink { categories in
                    cancellable?.cancel()
                    continuation.resume(returning: categories)
                }

            action()
        }
    }

    @MainActor
    static func waitUntil(
        timeout: TimeInterval = 2.0,
        condition: @escaping () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if condition() {
                return true
            }

            try? await Task.sleep(nanoseconds: 25_000_000)
        }

        return condition()
    }
}

private actor AttemptsCounter {
    private var count = 0

    func increment() -> Int {
        count += 1
        return count
    }

    func value() -> Int {
        count
    }
}

private enum TestError: Error {
    case sample
}
