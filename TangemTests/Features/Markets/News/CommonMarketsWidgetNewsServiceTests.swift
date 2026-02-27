//
//  CommonMarketsWidgetNewsServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Combine
import Testing
@testable import Tangem

@Suite("CommonMarketsWidgetNewsService Tests", .tags(.news))
struct CommonMarketsWidgetNewsServiceTests {
    @Test("Fetch sorts items by read status")
    func fetchSortsItemsByReadStatus() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadTrendingNewsHandler = { _, _ in
            TrendingNewsResponse(items: Self.makeItems(ids: [1, 2, 3]))
        }

        let readStatusProvider = InMemoryNewsReadStatusProvider()
        readStatusProvider.markAsRead(newsId: "2")

        try await Self.withInjected(apiService: apiService, readStatusProvider: readStatusProvider) {
            let service = CommonMarketsWidgetNewsService()
            let items = await Self.awaitSuccess(from: service) {
                service.fetch()
            }

            #expect(items.map(\.id) == ["1", "3", "2"])
        }
    }

    @Test("Updates order after read status change")
    func updatesOrderAfterReadStatusChange() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadTrendingNewsHandler = { _, _ in
            TrendingNewsResponse(items: Self.makeItems(ids: [1, 2, 3]))
        }

        let readStatusProvider = InMemoryNewsReadStatusProvider()

        try await Self.withInjected(apiService: apiService, readStatusProvider: readStatusProvider) {
            let service = CommonMarketsWidgetNewsService()
            let initial = await Self.awaitSuccess(from: service) {
                service.fetch()
            }

            #expect(initial.map(\.id) == ["1", "2", "3"])

            let updated = await Self.awaitNextSuccess(from: service) {
                readStatusProvider.markAsRead(newsId: "1")
            }

            #expect(updated.map(\.id) == ["2", "3", "1"])
        }
    }
}

private extension CommonMarketsWidgetNewsServiceTests {
    static func makeItems(ids: [Int]) -> [NewsDTO.List.Item] {
        ids.map { id in
            NewsDTO.List.Item(
                id: id,
                createdAt: Date(),
                score: Double(id),
                language: "en",
                isTrending: false,
                categories: [],
                relatedTokens: [],
                title: "Title \(id)",
                newsUrl: "https://example.com/\(id)"
            )
        }
    }

    static func withInjected(
        apiService: TangemApiService,
        readStatusProvider: NewsReadStatusProvider,
        operation: () async throws -> Void
    ) async throws {
        try await NewsTestsDependencyIsolation.shared.run {
            let previousService = InjectedValues[\.tangemApiService]
            let previousReadStatus = InjectedValues[\.newsReadStatusProvider]
            InjectedValues[\.tangemApiService] = apiService
            InjectedValues[\.newsReadStatusProvider] = readStatusProvider
            defer {
                InjectedValues[\.tangemApiService] = previousService
                InjectedValues[\.newsReadStatusProvider] = previousReadStatus
            }
            try await operation()
        }
    }

    static func awaitSuccess(
        from service: CommonMarketsWidgetNewsService,
        action: () -> Void
    ) async -> [TrendingNewsModel] {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = service.newsResultPublisher
                .sink { result in
                    if case .success(let items) = result {
                        cancellable?.cancel()
                        continuation.resume(returning: items)
                    }
                }

            action()
        }
    }

    static func awaitNextSuccess(
        from service: CommonMarketsWidgetNewsService,
        action: () -> Void
    ) async -> [TrendingNewsModel] {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = service.newsResultPublisher
                .dropFirst()
                .sink { result in
                    if case .success(let items) = result {
                        cancellable?.cancel()
                        continuation.resume(returning: items)
                    }
                }

            action()
        }
    }
}
