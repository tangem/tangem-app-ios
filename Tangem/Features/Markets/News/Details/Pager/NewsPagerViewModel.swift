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
final class NewsPagerViewModel: ObservableObject, Identifiable, Hashable {
    // MARK: - Identifiable & Hashable

    nonisolated let id: UUID = .init()

    nonisolated static func == (lhs: NewsPagerViewModel, rhs: NewsPagerViewModel) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Published Properties

    @Published var currentIndex: Int
    @Published private(set) var articles: [Int: ArticleState] = [:]
    @Published private(set) var likeStates: [Int: LikeState] = [:]
    @Published private(set) var newsIds: [Int]

    // MARK: - Public Properties

    let initialIndex: Int

    var currentNewsId: Int? {
        guard currentIndex >= 0, currentIndex < newsIds.count else { return nil }
        return newsIds[currentIndex]
    }

    var currentArticle: NewsDetailsViewModel.ArticleViewModel? {
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

    // MARK: - Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Private Properties

    private let dateFormatter: NewsDateFormatter
    private weak var coordinator: NewsDetailsRoutable?

    private var loadingTasks: [Int: AnyCancellable] = [:]
    private var relatedTokensViewModels: [Int: RelatedTokensViewModel] = [:]
    private var isLoadingMoreNews = false
    private let preloadThreshold = 3

    // MARK: - Init

    init(
        newsIds: [Int],
        initialIndex: Int,
        dateFormatter: NewsDateFormatter = NewsDateFormatter(),
        coordinator: NewsDetailsRoutable? = nil
    ) {
        self.newsIds = newsIds
        self.initialIndex = initialIndex
        currentIndex = initialIndex
        self.dateFormatter = dateFormatter
        self.coordinator = coordinator
    }

    func setCoordinator(_ coordinator: NewsDetailsRoutable) {
        self.coordinator = coordinator
    }

    // MARK: - View Actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .onAppear:
            loadCurrentAndAdjacentArticles()
        case .pageChanged(let newIndex):
            onPageChanged(to: newIndex)
        case .retry:
            retryCurrentArticle()
        case .back:
            coordinator?.dismissNewsDetails()
        case .share:
            guard let article = currentArticle else { return }
            coordinator?.share(url: article.newsUrl)
        case .openSource(let url):
            coordinator?.openURL(url)
        case .like(let newsId):
            toggleLike(for: newsId)
        }
    }

    func articleState(for newsId: Int) -> ArticleState {
        articles[newsId] ?? .loading
    }

    func likeState(for newsId: Int) -> LikeState {
        likeStates[newsId] ?? .idle(isLiked: false)
    }

    func relatedTokensViewModel(for article: NewsDetailsViewModel.ArticleViewModel) -> RelatedTokensViewModel {
        if let existing = relatedTokensViewModels[article.id] {
            return existing
        }

        let viewModel = RelatedTokensViewModel(tokens: article.relatedTokens, coordinator: coordinator)
        relatedTokensViewModels[article.id] = viewModel
        return viewModel
    }

    // MARK: - Private Methods

    private func onPageChanged(to newIndex: Int) {
        guard newIndex != currentIndex else { return }
        currentIndex = newIndex
        loadCurrentAndAdjacentArticles()
        checkAndLoadMoreNewsIfNeeded()
    }

    private func checkAndLoadMoreNewsIfNeeded() {
        let remainingItems = newsIds.count - currentIndex - 1

        guard remainingItems <= preloadThreshold,
              !isLoadingMoreNews,
              coordinator?.hasMoreNews == true else {
            return
        }

        isLoadingMoreNews = true

        Task { [weak self] in
            guard let self, let coordinator else {
                self?.isLoadingMoreNews = false
                return
            }

            let newIds = await coordinator.loadMoreNews()

            guard !newIds.isEmpty else {
                isLoadingMoreNews = false
                return
            }

            // Append only new IDs that aren't already in the list
            let existingSet = Set(newsIds)
            let uniqueNewIds = newIds.filter { !existingSet.contains($0) }

            if !uniqueNewIds.isEmpty {
                newsIds.append(contentsOf: uniqueNewIds)
            }

            isLoadingMoreNews = false
        }
    }

    private func loadCurrentAndAdjacentArticles() {
        // Load current
        if let currentId = currentNewsId {
            loadArticleIfNeeded(newsId: currentId)
        }

        // Preload previous
        if canGoBack {
            let prevId = newsIds[currentIndex - 1]
            loadArticleIfNeeded(newsId: prevId)
        }

        // Preload next
        if canGoForward {
            let nextId = newsIds[currentIndex + 1]
            loadArticleIfNeeded(newsId: nextId)
        }
    }

    private func loadArticleIfNeeded(newsId: Int) {
        // Skip if already loading or loaded
        if case .loading = articles[newsId] {
            return
        }
        if case .loaded = articles[newsId] {
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

            do {
                let request = NewsDTO.Details.Request(
                    newsId: newsId,
                    lang: Locale.current.language.languageCode?.identifier
                )
                let response = try await tangemApiService.loadNewsDetails(requestModel: request)
                let article = NewsDetailsViewModel.ArticleViewModel(from: response, dateFormatter: dateFormatter)
                articles[newsId] = .loaded(article)
            } catch {
                if error.isCancellationError {
                    return
                }

                articles[newsId] = .error
            }
        }.eraseToAnyCancellable()
    }

    private func toggleLike(for newsId: Int) {
        let currentState = likeState(for: newsId)
        guard !currentState.isLoading else { return }

        let newLikeValue = !currentState.isLiked
        likeStates[newsId] = .loading(isLiked: currentState.isLiked)

        Task { [weak self] in
            guard let self else { return }

            do {
                let request = NewsDTO.Like.Request(newsId: newsId, isLiked: newLikeValue)
                let response = try await tangemApiService.likeNews(requestModel: request)
                likeStates[newsId] = .idle(isLiked: response.isLiked)
            } catch {
                if error.isCancellationError {
                    return
                }
                // Revert on error
                likeStates[newsId] = .idle(isLiked: currentState.isLiked)
            }
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
        case openSource(URL)
        case like(Int)
    }
}

// MARK: - ArticleState

extension NewsPagerViewModel {
    enum ArticleState: Equatable {
        case loading
        case loaded(NewsDetailsViewModel.ArticleViewModel)
        case error

        static func == (lhs: ArticleState, rhs: ArticleState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.error, .error):
                return true
            case (.loaded(let l), .loaded(let r)):
                return l.id == r.id
            default:
                return false
            }
        }
    }
}

// MARK: - LikeState

extension NewsPagerViewModel {
    enum LikeState: Equatable {
        case idle(isLiked: Bool)
        case loading(isLiked: Bool)

        var isLiked: Bool {
            switch self {
            case .idle(let isLiked), .loading(let isLiked):
                return isLiked
            }
        }

        var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }
    }
}
