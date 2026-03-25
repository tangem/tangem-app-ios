//
//  NewsPagerViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Testing
@testable import Tangem

@MainActor
@Suite("NewsPagerViewModel Tests", .tags(.news))
struct NewsPagerViewModelTests {
    @Test("onAppear loads current and adjacent articles, marks current as read")
    func onAppearLoadsCurrentAndAdjacentArticlesAndMarksCurrentAsRead() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsDetailsHandler = { request in
            return Self.makeDetailsResponse(newsId: request.newsId)
        }

        let readStatusProvider = InMemoryNewsReadStatusProvider()

        try await Self.withInjected(apiService: apiService, readStatusProvider: readStatusProvider) {
            let viewModel = NewsPagerViewModel(newsIds: [1, 2, 3], initialIndex: 1)

            viewModel.handleViewAction(.onAppear)

            let didLoadCurrentAndAdjacent = await Self.waitUntil {
                viewModel.isLoading(for: 1) == false
                    && viewModel.isLoading(for: 2) == false
                    && viewModel.isLoading(for: 3) == false
                    && viewModel.isError(for: 1) == false
                    && viewModel.isError(for: 2) == false
                    && viewModel.isError(for: 3) == false
            }

            #expect(didLoadCurrentAndAdjacent)
            #expect(readStatusProvider.isRead(for: "2") == true)
        }
    }

    @Test("pageChanged near end appends unique ids from data source")
    func pageChangedNearEndAppendsUniqueIdsFromDataSource() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsDetailsHandler = { request in
            Self.makeDetailsResponse(newsId: request.newsId)
        }

        let dataSource = NewsPagerDataSourceStub(canFetchMore: true, idsToLoad: [2, 3, 4])

        try await Self.withInjected(apiService: apiService) {
            let viewModel = NewsPagerViewModel(
                newsIds: [1, 2],
                initialIndex: 0,
                dataSource: dataSource
            )

            viewModel.handleViewAction(.pageChanged(1))

            let didAppend = await Self.waitUntil {
                viewModel.newsIds == [1, 2, 3, 4]
            }

            #expect(didAppend)
            #expect(dataSource.loadMoreCalls == 1)
        }
    }

    @Test("pageChanged far from end does not request more ids")
    func pageChangedFarFromEndDoesNotRequestMoreIds() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsDetailsHandler = { request in
            Self.makeDetailsResponse(newsId: request.newsId)
        }

        let dataSource = NewsPagerDataSourceStub(canFetchMore: true, idsToLoad: [8, 9])

        try await Self.withInjected(apiService: apiService) {
            let viewModel = NewsPagerViewModel(
                newsIds: [1, 2, 3, 4, 5, 6, 7],
                initialIndex: 0,
                dataSource: dataSource
            )

            viewModel.handleViewAction(.pageChanged(1))

            #expect(dataSource.loadMoreCalls == 0)
            #expect(viewModel.newsIds == [1, 2, 3, 4, 5, 6, 7])
        }
    }

    @Test("retry reloads article after error")
    func retryReloadsArticleAfterError() async throws {
        let apiService = FakeTangemApiService()
        let deeplinkValidator = NewsDeeplinkValidationSpy()
        let attemptsCounter = AttemptsCounter()

        apiService.loadNewsDetailsHandler = { request in
            let attempt = await attemptsCounter.increment()
            if attempt == 1 {
                throw TestError.sample
            }

            return Self.makeDetailsResponse(newsId: request.newsId)
        }

        try await Self.withInjected(apiService: apiService, deeplinkValidationService: deeplinkValidator) {
            let viewModel = NewsPagerViewModel(newsIds: [10], initialIndex: 0)

            viewModel.handleViewAction(.onAppear)

            let didFail = await Self.waitUntil {
                viewModel.isError(for: 10)
            }

            #expect(didFail)
            #expect(deeplinkValidator.logMismatchCalls == [10])

            viewModel.handleViewAction(.retry)

            let didRecover = await Self.waitUntil {
                viewModel.isError(for: 10) == false && viewModel.isLoading(for: 10) == false
            }

            #expect(didRecover)
            #expect(deeplinkValidator.validateCalls.contains(10))
        }
    }

    @Test("share, open source and back route to coordinator")
    func shareOpenSourceAndBackRouteToCoordinator() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsDetailsHandler = { request in
            Self.makeDetailsResponse(
                newsId: request.newsId,
                relatedArticleURL: "https://example.com/source/\(request.newsId)"
            )
        }

        let coordinator = NewsDetailsRoutableSpy()

        try await Self.withInjected(apiService: apiService) {
            let viewModel = NewsPagerViewModel(newsIds: [11], initialIndex: 0, coordinator: coordinator)
            viewModel.handleViewAction(.onAppear)

            let didLoadArticle = await Self.waitUntil {
                viewModel.currentArticle != nil
            }

            #expect(didLoadArticle)

            viewModel.handleViewAction(.share)
            viewModel.handleViewAction(.back)

            let article = try #require(viewModel.currentArticle)
            let source = try #require(article.sources.first)
            let sourceURL = try #require(source.url)
            viewModel.handleViewAction(.openSource(source))

            #expect(coordinator.sharedURLs == [article.newsUrl])
            #expect(coordinator.dismissCallCount == 1)
            #expect(coordinator.openedURLs == [sourceURL])
        }
    }

    @Test("like toggles state")
    func likeTogglesState() async throws {
        let apiService = FakeTangemApiService()
        let likeService = InMemoryNewsLikeService()

        try await Self.withInjected(apiService: apiService, likeService: likeService) {
            let viewModel = NewsPagerViewModel(newsIds: [99], initialIndex: 0)

            #expect(viewModel.isLiked(for: 99) == false)

            viewModel.handleViewAction(.like(99))
            #expect(viewModel.isLiked(for: 99) == true)

            viewModel.handleViewAction(.like(99))
            #expect(viewModel.isLiked(for: 99) == false)
        }
    }

    @Test("relatedTokensViewModel is cached per article id")
    func relatedTokensViewModelIsCachedPerArticleId() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsDetailsHandler = { request in
            Self.makeDetailsResponse(
                newsId: request.newsId,
                relatedTokens: [NewsDTO.List.RelatedToken(id: "btc", symbol: "BTC", name: "Bitcoin")]
            )
        }

        try await Self.withInjected(apiService: apiService) {
            let viewModel = NewsPagerViewModel(newsIds: [55], initialIndex: 0)
            viewModel.handleViewAction(.onAppear)

            let didLoadArticle = await Self.waitUntil {
                viewModel.currentArticle != nil
            }

            #expect(didLoadArticle)

            let article = try #require(viewModel.currentArticle)
            let first = viewModel.relatedTokensViewModel(for: article)
            let second = viewModel.relatedTokensViewModel(for: article)

            #expect(first === second)
        }
    }

    @Test("NewsDetailsViewModel onAppear loads article")
    func newsDetailsViewModelOnAppearLoadsArticle() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsDetailsHandler = { request in
            Self.makeDetailsResponse(newsId: request.newsId)
        }

        try await Self.withInjected(apiService: apiService) {
            let viewModel = NewsDetailsViewModel(newsId: 321)
            viewModel.handleViewAction(.onAppear)

            let didLoad = await Self.waitUntil {
                viewModel.loadingState == .loaded && viewModel.article?.id == 321
            }

            #expect(didLoad)
        }
    }

    @Test("NewsDetailsViewModel retry recovers from error")
    func newsDetailsViewModelRetryRecoversFromError() async throws {
        let apiService = FakeTangemApiService()
        let attemptsCounter = AttemptsCounter()
        apiService.loadNewsDetailsHandler = { request in
            let attempt = await attemptsCounter.increment()
            if attempt == 1 {
                throw TestError.sample
            }

            return Self.makeDetailsResponse(newsId: request.newsId)
        }

        try await Self.withInjected(apiService: apiService) {
            let viewModel = NewsDetailsViewModel(newsId: 555)
            viewModel.handleViewAction(.onAppear)

            let didFail = await Self.waitUntil {
                viewModel.loadingState == .error
            }
            #expect(didFail)

            viewModel.handleViewAction(.retry)

            let didRecover = await Self.waitUntil {
                viewModel.loadingState == .loaded && viewModel.article?.id == 555
            }
            #expect(didRecover)
        }
    }

    @Test("NewsDetailsViewModel routes share, source and back to coordinator")
    func newsDetailsViewModelRoutesActionsToCoordinator() async throws {
        let apiService = FakeTangemApiService()
        apiService.loadNewsDetailsHandler = { request in
            Self.makeDetailsResponse(newsId: request.newsId)
        }

        let coordinator = NewsDetailsRoutableSpy()

        try await Self.withInjected(apiService: apiService) {
            let viewModel = NewsDetailsViewModel(newsId: 700, coordinator: coordinator)
            viewModel.handleViewAction(.onAppear)

            let didLoad = await Self.waitUntil {
                viewModel.loadingState == .loaded && viewModel.article != nil
            }
            #expect(didLoad)

            let sourceURL = try #require(URL(string: "https://example.com/source/700"))
            viewModel.handleViewAction(.share)
            viewModel.handleViewAction(.openSource(sourceURL))
            viewModel.handleViewAction(.back)

            #expect(coordinator.sharedURLs == [viewModel.article?.newsUrl].compactMap { $0 })
            #expect(coordinator.openedURLs == [sourceURL])
            #expect(coordinator.dismissCallCount == 1)
        }
    }
}

private extension NewsPagerViewModelTests {
    static func withInjected(
        apiService: TangemApiService,
        readStatusProvider: NewsReadStatusProvider = InMemoryNewsReadStatusProvider(),
        likeService: NewsLikeService = InMemoryNewsLikeService(),
        deeplinkValidationService: NewsDeeplinkValidating = NewsDeeplinkValidationService(),
        operation: () async throws -> Void
    ) async throws {
        try await NewsTestsDependencyIsolation.shared.run {
            let previousApiService = InjectedValues[\.tangemApiService]
            let previousReadStatusProvider = InjectedValues[\.newsReadStatusProvider]
            let previousLikeService = InjectedValues[\.newsLikeService]
            let previousDeeplinkValidationService = InjectedValues[\.newsDeeplinkValidationService]

            InjectedValues[\.tangemApiService] = apiService
            InjectedValues[\.newsReadStatusProvider] = readStatusProvider
            InjectedValues[\.newsLikeService] = likeService
            InjectedValues[\.newsDeeplinkValidationService] = deeplinkValidationService

            defer {
                InjectedValues[\.tangemApiService] = previousApiService
                InjectedValues[\.newsReadStatusProvider] = previousReadStatusProvider
                InjectedValues[\.newsLikeService] = previousLikeService
                InjectedValues[\.newsDeeplinkValidationService] = previousDeeplinkValidationService
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

    static func makeDetailsResponse(
        newsId: Int,
        relatedArticleURL: String? = nil,
        relatedTokens: [NewsDTO.List.RelatedToken] = []
    ) -> NewsDTO.Details.Response {
        NewsDTO.Details.Response(
            id: newsId,
            createdAt: "2026-02-09T10:00:00Z",
            score: 9.5,
            language: "en",
            isTrending: false,
            categories: [NewsDTO.List.Category(id: 1, name: "Markets")],
            relatedTokens: relatedTokens,
            title: "News \(newsId)",
            newsUrl: "https://example.com/news/markets/\(newsId)-slug",
            shortContent: "Short \(newsId)",
            content: "Content \(newsId)",
            relatedArticles: [
                NewsDTO.Details.RelatedArticle(
                    id: newsId + 1_000,
                    title: "Related \(newsId)",
                    media: NewsDTO.Details.Media(id: 1, name: "Tangem"),
                    language: "en",
                    publishedAt: "2026-02-09T10:00:00Z",
                    url: relatedArticleURL,
                    imageUrl: nil
                ),
            ]
        )
    }
}

private final class NewsPagerDataSourceStub: NewsPagerDataSource {
    private(set) var canFetchMore: Bool
    private let idsToLoad: [Int]
    private(set) var loadMoreCalls = 0

    init(canFetchMore: Bool, idsToLoad: [Int]) {
        self.canFetchMore = canFetchMore
        self.idsToLoad = idsToLoad
    }

    func loadMoreNewsIds() async -> [Int] {
        loadMoreCalls += 1
        canFetchMore = false
        return idsToLoad
    }
}

@MainActor
private final class NewsDetailsRoutableSpy: NewsDetailsRoutable {
    private(set) var dismissCallCount = 0
    private(set) var sharedURLs: [String] = []
    private(set) var openedURLs: [URL] = []

    func dismissNewsDetails() {
        dismissCallCount += 1
    }

    func share(url: String) {
        sharedURLs.append(url)
    }

    func openURL(_ url: URL) {
        openedURLs.append(url)
    }

    func openTokenDetails(_ token: MarketsTokenModel) {}
}

private final class NewsDeeplinkValidationSpy: NewsDeeplinkValidating {
    private(set) var validateCalls: [Int] = []
    private(set) var logMismatchCalls: [Int] = []

    func setDeeplinkURL(_ url: String?) {}

    func validateAndLogMismatchIfNeeded(newsId: Int, actualNewsURL: String) -> Bool {
        validateCalls.append(newsId)
        return false
    }

    func logMismatchOnError(newsId: Int, error: Error) -> Bool {
        logMismatchCalls.append(newsId)
        return true
    }
}

private enum TestError: Error {
    case sample
}

private actor AttemptsCounter {
    private var count = 0

    func increment() -> Int {
        count += 1
        return count
    }
}
