//
//  NewsDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

@MainActor
final class NewsDetailsViewModel: ObservableObject, Identifiable, Hashable {
    nonisolated var id: Int { newsId }

    nonisolated static func == (lhs: NewsDetailsViewModel, rhs: NewsDetailsViewModel) -> Bool {
        lhs.newsId == rhs.newsId
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(newsId)
    }

    // MARK: - Published Properties

    @Published private(set) var loadingState: LoadingState = .loading
    @Published private(set) var article: ArticleViewModel?

    // MARK: - Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Private Properties

    private let newsId: Int
    private let dateFormatter: NewsDateFormatter
    private weak var coordinator: NewsDetailsRoutable?

    private var taskCancellable: AnyCancellable?

    // MARK: - Init

    init(
        newsId: Int,
        dateFormatter: NewsDateFormatter = NewsDateFormatter(),
        coordinator: NewsDetailsRoutable? = nil
    ) {
        self.newsId = newsId
        self.dateFormatter = dateFormatter
        self.coordinator = coordinator
    }

    // MARK: - View Actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .onAppear:
            loadDetails()
        case .retry:
            loadDetails()
        case .back:
            coordinator?.dismissNewsDetails()
        case .share:
            guard let article else { return }
            coordinator?.share(url: article.newsUrl)
        case .openSource(let url):
            coordinator?.openURL(url)
        }
    }

    // MARK: - Private Methods

    private func loadDetails() {
        loadingState = .loading

        taskCancellable?.cancel()
        taskCancellable = Task { [weak self] in
            guard let self else { return }

            do {
                let request = NewsDTO.Details.Request(
                    newsId: newsId,
                    lang: Locale.current.language.languageCode?.identifier
                )
                let response = try await tangemApiService.loadNewsDetails(requestModel: request)
                article = ArticleViewModel(from: response, dateFormatter: dateFormatter)
                loadingState = .loaded
            } catch {
                if error.isCancellationError {
                    return
                }
                loadingState = .error
            }
        }.eraseToAnyCancellable()
    }
}

// MARK: - ViewAction

extension NewsDetailsViewModel {
    enum ViewAction {
        case onAppear
        case retry
        case back
        case share
        case openSource(URL)
    }
}

// MARK: - LoadingState

extension NewsDetailsViewModel {
    enum LoadingState: Equatable {
        case loading
        case loaded
        case error
    }
}

// MARK: - ArticleViewModel

extension NewsDetailsViewModel {
    struct ArticleViewModel {
        let id: Int
        let title: String
        let score: String
        let relativeTime: String
        let isTrending: Bool
        let categories: [Category]
        let relatedTokens: [RelatedToken]
        let shortContent: String
        let content: String
        let newsUrl: String
        let sources: [Source]

        init(from response: NewsDTO.Details.Response, dateFormatter: NewsDateFormatter) {
            id = response.id
            title = response.title
            score = String(format: "%.1f", response.score)
            relativeTime = dateFormatter.formatDetailDate(from: response.createdAt)
            isTrending = response.isTrending
            categories = response.categories.map { Category(id: $0.id, name: $0.name) }
            relatedTokens = response.relatedTokens.map { RelatedToken(id: $0.id, symbol: $0.symbol, name: $0.name) }
            shortContent = response.shortContent
            content = response.content
            newsUrl = response.newsUrl
            sources = response.originalArticles.map { Source(from: $0, dateFormatter: dateFormatter) }
        }

        static let placeholder = ArticleViewModel(
            id: 0,
            title: String(repeating: " ", count: 50),
            score: "0.0",
            relativeTime: "",
            isTrending: false,
            categories: [],
            relatedTokens: [],
            shortContent: String(repeating: " ", count: 100),
            content: String(repeating: " ", count: 300),
            newsUrl: "",
            sources: []
        )

        private init(
            id: Int,
            title: String,
            score: String,
            relativeTime: String,
            isTrending: Bool,
            categories: [Category],
            relatedTokens: [RelatedToken],
            shortContent: String,
            content: String,
            newsUrl: String,
            sources: [Source]
        ) {
            self.id = id
            self.title = title
            self.score = score
            self.relativeTime = relativeTime
            self.isTrending = isTrending
            self.categories = categories
            self.relatedTokens = relatedTokens
            self.shortContent = shortContent
            self.content = content
            self.newsUrl = newsUrl
            self.sources = sources
        }
    }

    struct Category: Identifiable {
        let id: Int
        let name: String
    }

    struct RelatedToken: Identifiable {
        let id: String
        let symbol: String
        let name: String

        var iconURL: URL {
            IconURLBuilder().tokenIconURL(id: id, size: .small)
        }
    }

    struct Source: Identifiable {
        let id: Int
        let title: String
        let sourceName: String
        let publishedAt: String
        let url: URL?
        let imageUrl: URL?

        init(from article: NewsDTO.Details.OriginalArticle, dateFormatter: NewsDateFormatter) {
            id = article.id
            title = article.title ?? ""
            sourceName = article.sourceName ?? ""
            if let publishedAt = article.publishedAt {
                self.publishedAt = dateFormatter.formatRelativeTime(from: publishedAt)
            } else {
                publishedAt = ""
            }
            url = article.url.flatMap { URL(string: $0) }
            imageUrl = article.imageUrl.flatMap { URL(string: $0) }
        }
    }
}

// MARK: - NewsDetailsRoutable

protocol NewsDetailsRoutable: AnyObject {
    func dismissNewsDetails()
    func share(url: String)
    func openURL(_ url: URL)
    func openTokenDetails(_ token: MarketsTokenModel)
    func loadMoreNews() async -> [Int]
    @MainActor var hasMoreNews: Bool { get }
}
