//
//  NewsPagerDataSourceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Combine
import Testing
@testable import Tangem

@MainActor
@Suite("NewsPagerDataSource Tests", .tags(.news))
struct NewsPagerDataSourceTests {
    @Test("Returns empty ids when provider cannot fetch more")
    func returnsEmptyIdsWhenProviderCannotFetchMore() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsListHandler = { _ in
            Self.makeResponse(page: 1, ids: [1], hasNext: false)
        }

        let provider = NewsDataProvider(limitPerPage: 1)
        try await Self.withInjected(apiService) {
            _ = await Self.collectEvents(from: provider, count: 2) {
                provider.fetch()
            }

            let dataSource = NewsDataProviderPagerDataSource(provider: provider)
            let ids = await dataSource.loadMoreNewsIds()

            #expect(ids.isEmpty)
        }
    }

    @Test("Loads ids from next page")
    func loadsIdsFromNextPage() async throws {
        let responses = [
            Self.makeResponse(page: 1, ids: [1], hasNext: true),
            Self.makeResponse(page: 2, ids: [2, 3], hasNext: false),
        ]
        var responseIndex = 0

        let apiService = FakeTangemApiService()
        apiService.loadNewsListHandler = { _ in
            defer { responseIndex += 1 }
            return responses[responseIndex]
        }

        let provider = NewsDataProvider(limitPerPage: 2)
        try await Self.withInjected(apiService) {
            _ = await Self.collectEvents(from: provider, count: 2) {
                provider.fetch()
            }

            let dataSource = NewsDataProviderPagerDataSource(provider: provider)
            let ids = await dataSource.loadMoreNewsIds()

            #expect(ids == [2, 3])
        }
    }

    @Test("Returns empty ids when pagination request fails")
    func returnsEmptyIdsWhenPaginationRequestFails() async throws {
        enum TestError: Error {
            case failed
        }

        var requestIndex = 0
        let apiService = FakeTangemApiService()
        apiService.loadNewsListHandler = { _ in
            requestIndex += 1
            if requestIndex == 1 {
                return Self.makeResponse(page: 1, ids: [1], hasNext: true)
            }

            throw TestError.failed
        }

        let provider = NewsDataProvider(limitPerPage: 1)
        try await Self.withInjected(apiService) {
            _ = await Self.collectEvents(from: provider, count: 2) {
                provider.fetch()
            }

            let dataSource = NewsDataProviderPagerDataSource(provider: provider)
            let ids = await dataSource.loadMoreNewsIds()

            #expect(ids.isEmpty)
        }
    }

    @Test("Single data source never fetches more")
    func singleDataSourceNeverFetchesMore() async {
        let dataSource = SingleNewsDataSource()

        #expect(dataSource.canFetchMore == false)
        #expect(await dataSource.loadMoreNewsIds() == [])
    }
}

private extension NewsPagerDataSourceTests {
    static func makeResponse(page: Int, ids: [Int], hasNext: Bool) -> NewsDTO.List.Response {
        NewsDTO.List.Response(
            meta: NewsDTO.List.Meta(page: page, limit: ids.count, total: ids.count, hasNext: hasNext, asOf: "as-of"),
            items: ids.map { id in
                NewsDTO.List.Item(
                    id: id,
                    createdAt: Date(),
                    score: 1.0,
                    language: "en",
                    isTrending: false,
                    categories: [],
                    relatedTokens: [],
                    title: "News \(id)",
                    newsUrl: "https://example.com/\(id)"
                )
            }
        )
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
}
