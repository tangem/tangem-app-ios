//
//  NewsPagerViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

@MainActor
final class NewsPagerViewModel: MarketsBaseViewModel {
    // MARK: - Published Properties

    @Published var currentIndex: Int
    @Published private(set) var newsIds: [Int]

    // MARK: - Public Properties

    let initialIndex: Int
    let isDeeplinkMode: Bool

    var currentNewsId: Int? {
        guard currentIndex >= 0, currentIndex < newsIds.count else { return nil }
        return newsIds[currentIndex]
    }

    var currentArticle: NewsDetailsViewModel.ArticleModel? {
        guard let newsId = currentNewsId,
              case .loaded(let article) = articles[newsId] else {
            return nil
        }
        return article
    }

    var isCurrentArticleLoading: Bool {
        guard let newsId = currentNewsId else { return true }
        return articles[newsId] == .loading || articles[newsId] == nil
    }

    var canGoBack: Bool {
        currentIndex > 0
    }

    var canGoForward: Bool {
        currentIndex < newsIds.count - 1
    }

    var shouldShowPageIndicator: Bool {
        !isDeeplinkMode && newsIds.count > 1
    }

    var shouldShowNavigationBar: Bool {
        !isDeeplinkMode
    }

    // MARK: - Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.newsReadStatusProvider) private var readStatusProvider: NewsReadStatusProvider
    @Injected(\.newsLikeService) private var likeService: NewsLikeService
    @Injected(\.newsDeeplinkValidationService) private var newsDeeplinkValidationService: NewsDeeplinkValidating

    // MARK: - Private Properties

    private let dateFormatter: NewsDateFormatter
    private let dataSource: NewsPagerDataSource?
    private let analyticsSource: Analytics.ParameterValue?
    private weak var coordinator: NewsDetailsRoutable?

    @Published private var articles: [Int: ArticleState] = [:]
    private var loadingTasks: [Int: AnyCancellable] = [:]
    private var relatedTokensViewModels: [Int: RelatedTokensViewModel] = [:]
    private var isLoadingMoreNews = false
    private let preloadThreshold = 3
    private var loggedLikeNewsIds: Set<Int> = []

    // MARK: - Init

    init(
        newsIds: [Int],
        initialIndex: Int,
        isDeeplinkMode: Bool = false,
        dateFormatter: NewsDateFormatter = NewsDateFormatter(),
        dataSource: NewsPagerDataSource? = nil,
        analyticsSource: Analytics.ParameterValue? = nil,
        coordinator: NewsDetailsRoutable? = nil
    ) {
        self.newsIds = newsIds
        self.initialIndex = initialIndex
        self.isDeeplinkMode = isDeeplinkMode
        currentIndex = initialIndex
        self.dateFormatter = dateFormatter
        self.dataSource = dataSource
        self.analyticsSource = analyticsSource
        self.coordinator = coordinator

        // `OverlayContentStateObserver` doesn't provide an initial progress/state snapshot.
        // When this screen is pushed into a `NavigationStack`, the overlay is typically already expanded,
        // and without a proper initial value the content would stay hidden (opacity == 0).
        super.init(overlayContentProgressInitialValue: 1.0)
    }

    func setCoordinator(_ coordinator: NewsDetailsRoutable) {
        self.coordinator = coordinator
    }

    // MARK: - Public Methods for View

    func isLoading(for newsId: Int) -> Bool {
        articleState(for: newsId) == .loading
    }

    func article(for newsId: Int) -> NewsDetailsViewModel.ArticleModel {
        if case .loaded(let article) = articleState(for: newsId) {
            return article
        }
        return .placeholder
    }

    func isError(for newsId: Int) -> Bool {
        articleState(for: newsId) == .error
    }

    func isLiked(for newsId: Int) -> Bool {
        likeService.isLiked(newsId: newsId)
    }

    func relatedTokensViewModel(for article: NewsDetailsViewModel.ArticleModel) -> RelatedTokensViewModel {
        if let existing = relatedTokensViewModels[article.id] {
            return existing
        }

        let viewModel = RelatedTokensViewModel(tokens: article.relatedTokens, newsId: article.id, coordinator: coordinator)
        relatedTokensViewModels[article.id] = viewModel
        return viewModel
    }

    func isValidIndex(_ index: Int) -> Bool {
        index >= 0 && index < newsIds.count
    }

    // MARK: - View Actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .onAppear:
            loadCurrentAndAdjacentArticles()
            markCurrentAsRead()
        case .pageChanged(let newIndex):
            onPageChanged(to: newIndex)
            markCurrentAsRead()
        case .retry:
            retryCurrentArticle()
        case .back:
            coordinator?.dismissNewsDetails()
        case .share:
            guard let article = currentArticle else { return }
            coordinator?.share(url: article.newsUrl)
        case .openSource(let source):
            guard let newsId = currentNewsId, let url = source.url else { return }
            Analytics.log(
                event: .newsRelatedClicked,
                params: [
                    .newsId: String(newsId),
                    .relatedNewsId: String(source.id),
                ]
            )
            coordinator?.openURL(url)
        case .like(let newsId):
            toggleLike(for: newsId)
        }
    }

    // MARK: - Private Methods

    private func articleState(for newsId: Int) -> ArticleState {
        articles[newsId] ?? .loading
    }

    private func onPageChanged(to newIndex: Int) {
        guard newIndex != currentIndex else { return }
        currentIndex = newIndex
        loadCurrentAndAdjacentArticles()
        checkAndLoadMoreNewsIfNeeded()
    }

    private func markCurrentAsRead() {
        guard let newsId = currentNewsId else { return }

        let wasRead = readStatusProvider.isRead(for: String(newsId))
        readStatusProvider.markAsRead(newsId: String(newsId))

        if !wasRead {
            var params: [Analytics.ParameterKey: String] = [.newsId: String(newsId)]
            if let analyticsSource {
                params[.source] = analyticsSource.rawValue
            }
            Analytics.log(event: .newsArticleOpened, params: params)
        }
    }

    private func checkAndLoadMoreNewsIfNeeded() {
        let remainingItemsCount = newsIds.count - currentIndex - 1

        guard remainingItemsCount <= preloadThreshold,
              !isLoadingMoreNews,
              dataSource?.canFetchMore == true else {
            return
        }

        isLoadingMoreNews = true

        Task { [weak self] in
            guard let self, let dataSource else {
                self?.isLoadingMoreNews = false
                return
            }

            let newIds = await dataSource.loadMoreNewsIds()

            guard !newIds.isEmpty else {
                isLoadingMoreNews = false
                return
            }

            let existingSet = Set(newsIds)
            let uniqueNewIds = newIds.filter { !existingSet.contains($0) }

            if !uniqueNewIds.isEmpty {
                newsIds.append(contentsOf: uniqueNewIds)
            }

            isLoadingMoreNews = false
        }
    }

    private func loadCurrentAndAdjacentArticles() {
        if let currentId = currentNewsId {
            loadArticleIfNeeded(newsId: currentId)
        }

        if canGoBack, currentIndex > 0, currentIndex - 1 < newsIds.count {
            let prevId = newsIds[currentIndex - 1]
            loadArticleIfNeeded(newsId: prevId)
        }

        if canGoForward, currentIndex + 1 < newsIds.count {
            let nextId = newsIds[currentIndex + 1]
            loadArticleIfNeeded(newsId: nextId)
        }
    }

    private func loadArticleIfNeeded(newsId: Int) {
        guard articles[newsId] == nil || articles[newsId] == .error else {
            return
        }

        articles[newsId] = .loading
        loadArticle(newsId: newsId)
    }

    private func retryCurrentArticle() {
        guard let newsId = currentNewsId else { return }
        articles[newsId] = .loading
        loadArticle(newsId: newsId)
    }

    private func loadArticle(newsId: Int) {
        loadingTasks[newsId]?.cancel()
        loadingTasks[newsId] = Task { [weak self] in
            guard let self else { return }

            defer {
                loadingTasks.removeValue(forKey: newsId)
            }

            do {
                let request = NewsDTO.Details.Request(
                    newsId: newsId,
                    lang: Locale.current.language.languageCode?.identifier
                )
                let response = try await tangemApiService.loadNewsDetails(requestModel: request)
                let article = NewsDetailsViewModel.ArticleModel(from: response, dateFormatter: dateFormatter)
                articles[newsId] = .loaded(article)

                newsDeeplinkValidationService.validateAndLogMismatchIfNeeded(
                    newsId: newsId,
                    actualNewsURL: article.newsUrl
                )
            } catch {
                if error.isCancellationError {
                    return
                }

                articles[newsId] = .error
                var params = error.marketsAnalyticsParams
                params[.newsId] = String(newsId)
                Analytics.log(event: .newsArticleLoadError, params: params)

                newsDeeplinkValidationService.logMismatchOnError(newsId: newsId, error: error)
            }
        }.eraseToAnyCancellable()
    }

    private func toggleLike(for newsId: Int) {
        let wasLiked = likeService.isLiked(newsId: newsId)
        likeService.toggleLike(newsId: newsId)
        objectWillChange.send()

        if !wasLiked, !loggedLikeNewsIds.contains(newsId) {
            loggedLikeNewsIds.insert(newsId)
            Analytics.log(event: .newsLikeClicked, params: [.newsId: String(newsId)])
        }
    }
}

// MARK: - ViewAction

extension NewsPagerViewModel {
    enum ViewAction {
        case onAppear
        case pageChanged(Int)
        case retry
        case back
        case share
        case openSource(NewsDetailsViewModel.Source)
        case like(Int)
    }
}

// MARK: - ArticleState

extension NewsPagerViewModel {
    enum ArticleState: Equatable {
        case loading
        case loaded(NewsDetailsViewModel.ArticleModel)
        case error
    }
}

// MARK: - Hashable

extension NewsPagerViewModel: Hashable {
    nonisolated static func == (lhs: NewsPagerViewModel, rhs: NewsPagerViewModel) -> Bool {
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
