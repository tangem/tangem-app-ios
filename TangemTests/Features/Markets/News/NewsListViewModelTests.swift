//
//  NewsListViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Testing
@testable import Tangem

@MainActor
@Suite("NewsListViewModel Tests", .tags(.news))
struct NewsListViewModelTests {
    @Test("onFirstAppear loads categories and news")
    func onFirstAppearLoadsCategoriesAndNews() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsCategoriesHandler = {
            NewsDTO.Categories.Response(items: [
                NewsDTO.Categories.Item(id: 1, name: "Markets"),
                NewsDTO.Categories.Item(id: 2, name: "Regulation"),
            ])
        }
        apiService.loadNewsListHandler = { _ in
            Self.makeListResponse(ids: [100, 200], page: 1, hasNext: false)
        }

        try await Self.withInjected(apiService: apiService) {
            let viewModel = NewsListViewModel(dataProvider: NewsDataProvider(limitPerPage: 20))
            viewModel.handleViewAction(.onFirstAppear)

            let didLoad = await Self.waitUntil {
                viewModel.loadingState == .allDataLoaded
                    && viewModel.newsItems.map(\.id) == [100, 200]
                    && viewModel.categories.map(\.id) == [1, 2]
            }

            #expect(didLoad)
        }
    }

    @Test("Read status update marks existing item as read")
    func readStatusUpdateMarksExistingItemAsRead() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsListHandler = { _ in
            Self.makeListResponse(ids: [1], page: 1, hasNext: false)
        }

        let readStatusProvider = InMemoryNewsReadStatusProvider()

        try await Self.withInjected(apiService: apiService, readStatusProvider: readStatusProvider) {
            let viewModel = NewsListViewModel(dataProvider: NewsDataProvider(limitPerPage: 20))
            viewModel.handleViewAction(.onFirstAppear)

            let didLoad = await Self.waitUntil {
                viewModel.newsItems.count == 1
            }
            #expect(didLoad)
            #expect(viewModel.newsItems.first?.isRead == false)

            readStatusProvider.markAsRead(newsId: "1")

            let didUpdateReadStatus = await Self.waitUntil {
                viewModel.newsItems.first?.isRead == true
            }

            #expect(didUpdateReadStatus)
        }
    }

    @Test("onNewsSelected opens details with full ids and selected index")
    func onNewsSelectedOpensDetailsWithFullIdsAndSelectedIndex() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsListHandler = { _ in
            Self.makeListResponse(ids: [10, 20, 30], page: 1, hasNext: false)
        }

        let coordinator = NewsListRoutableSpy()

        try await Self.withInjected(apiService: apiService) {
            let viewModel = NewsListViewModel(
                dataProvider: NewsDataProvider(limitPerPage: 20),
                coordinator: coordinator
            )
            viewModel.handleViewAction(.onFirstAppear)

            let didLoad = await Self.waitUntil {
                viewModel.newsItems.map(\.id) == [10, 20, 30]
            }
            #expect(didLoad)

            viewModel.handleViewAction(.onNewsSelected(20))

            #expect(coordinator.openNewsDetailsCalls.count == 1)
            #expect(coordinator.openNewsDetailsCalls.first?.newsIds == [10, 20, 30])
            #expect(coordinator.openNewsDetailsCalls.first?.selectedIndex == 1)
            #expect(coordinator.openNewsDetailsCalls.first?.hasMoreNews == nil)
        }
    }

    @Test("loadMore failure with existing items switches to paginationError")
    func loadMoreFailureWithExistingItemsSwitchesToPaginationError() async throws {
        let apiService = FakeTangemApiService()
        let responses = [
            Self.makeListResponse(ids: [1], page: 1, hasNext: true),
        ]
        let requestCounter = AttemptsCounter()

        apiService.loadNewsListHandler = { _ in
            let attempt = await requestCounter.increment()
            if attempt == 1 {
                return responses[0]
            }

            throw TestError.sample
        }

        try await Self.withInjected(apiService: apiService) {
            let viewModel = NewsListViewModel(dataProvider: NewsDataProvider(limitPerPage: 1))
            viewModel.handleViewAction(.onFirstAppear)

            let didLoadFirstPage = await Self.waitUntil {
                viewModel.loadingState == .loaded
                    && viewModel.newsItems.map(\.id) == [1]
            }
            #expect(didLoadFirstPage)

            viewModel.handleViewAction(.loadMore)

            let didSwitchToPaginationError = await Self.waitUntil {
                viewModel.loadingState == .paginationError
            }

            #expect(didSwitchToPaginationError)
        }
    }

    @Test("Initial empty response switches to noResults")
    func initialEmptyResponseSwitchesToNoResults() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsListHandler = { _ in
            Self.makeListResponse(ids: [], page: 1, hasNext: false)
        }

        try await Self.withInjected(apiService: apiService) {
            let viewModel = NewsListViewModel(dataProvider: NewsDataProvider(limitPerPage: 20))
            viewModel.handleViewAction(.onFirstAppear)

            let didSwitchToNoResults = await Self.waitUntil {
                viewModel.loadingState == .noResults && viewModel.newsItems.isEmpty
            }

            #expect(didSwitchToNoResults)
        }
    }
}

private extension NewsListViewModelTests {
    static func withInjected(
        apiService: TangemApiService,
        readStatusProvider: NewsReadStatusProvider = InMemoryNewsReadStatusProvider(),
        operation: () async throws -> Void
    ) async throws {
        try await NewsTestsDependencyIsolation.shared.run {
            let previousApiService = InjectedValues[\.tangemApiService]
            let previousReadStatusProvider = InjectedValues[\.newsReadStatusProvider]

            InjectedValues[\.tangemApiService] = apiService
            InjectedValues[\.newsReadStatusProvider] = readStatusProvider

            defer {
                InjectedValues[\.tangemApiService] = previousApiService
                InjectedValues[\.newsReadStatusProvider] = previousReadStatusProvider
            }

            try await operation()
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

    static func makeListResponse(ids: [Int], page: Int, hasNext: Bool) -> NewsDTO.List.Response {
        NewsDTO.List.Response(
            meta: NewsDTO.List.Meta(
                page: page,
                limit: ids.count,
                total: ids.count,
                hasNext: hasNext,
                asOf: "2026-02-09T10:00:00Z"
            ),
            items: ids.map { Self.makeListItem(id: $0) }
        )
    }

    static func makeListItem(id: Int) -> NewsDTO.List.Item {
        NewsDTO.List.Item(
            id: id,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            score: 7.7,
            language: "en",
            isTrending: false,
            categories: [NewsDTO.List.Category(id: 1, name: "Markets")],
            relatedTokens: [],
            title: "Title \(id)",
            newsUrl: "https://example.com/news/\(id)"
        )
    }
}

@MainActor
private final class NewsListRoutableSpy: NewsListRoutable {
    private(set) var dismissCallCount = 0
    private(set) var openNewsDetailsCalls: [(newsIds: [Int], selectedIndex: Int, hasMoreNews: Bool?)] = []

    func dismiss() {
        dismissCallCount += 1
    }

    func openNewsDetails(newsIds: [Int], selectedIndex: Int, hasMoreNews: Bool?) {
        openNewsDetailsCalls.append((newsIds: newsIds, selectedIndex: selectedIndex, hasMoreNews: hasMoreNews))
    }
}

private actor AttemptsCounter {
    private var count = 0

    func increment() -> Int {
        count += 1
        return count
    }
}

private enum TestError: Error {
    case sample
}
