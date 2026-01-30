//
//  NewsArticleModels.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - ArticleModel

struct NewsArticleModel: Equatable, Identifiable {
    let id: Int
    let title: String
    let score: String
    let relativeTime: String
    let isTrending: Bool
    let categories: [NewsCategory]
    let relatedTokens: [NewsRelatedToken]
    let shortContent: String
    let content: String
    let newsUrl: String
    let sources: [NewsSource]

    init(from response: NewsDTO.Details.Response, dateFormatter: NewsDateFormatter) {
        id = response.id
        title = response.title
        score = String(format: "%.1f", response.score)
        relativeTime = dateFormatter.formatRelativeTime(from: response.createdAt)
        isTrending = response.isTrending
        categories = response.categories.map { NewsCategory(id: $0.id, name: $0.name) }
        relatedTokens = response.relatedTokens.map { NewsRelatedToken(id: $0.id, symbol: $0.symbol, name: $0.name) }
        shortContent = response.shortContent
        content = response.content
        newsUrl = response.newsUrl
        sources = response.relatedArticles.map { NewsSource(from: $0, dateFormatter: dateFormatter) }
    }

    static let placeholder = NewsArticleModel(
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
        categories: [NewsCategory],
        relatedTokens: [NewsRelatedToken],
        shortContent: String,
        content: String,
        newsUrl: String,
        sources: [NewsSource]
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

// MARK: - NewsCategory

struct NewsCategory: Identifiable, Equatable {
    let id: Int
    let name: String
}

// MARK: - NewsRelatedToken

struct NewsRelatedToken: Identifiable, Equatable {
    private static let iconBuilder = IconURLBuilder()

    let id: String
    let symbol: String
    let name: String

    var iconURL: URL {
        Self.iconBuilder.tokenIconURL(id: id, size: .small)
    }
}

// MARK: - NewsSource

struct NewsSource: Identifiable, Equatable {
    let id: Int
    let title: String
    let sourceName: String
    let publishedAt: String
    let url: URL?
    let imageUrl: URL?

    init(from article: NewsDTO.Details.RelatedArticle, dateFormatter: NewsDateFormatter) {
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

// MARK: - NewsDetailsRoutable

@MainActor
protocol NewsDetailsRoutable: AnyObject {
    func dismissNewsDetails()
    func share(url: String)
    func openURL(_ url: URL)
    func openTokenDetails(_ token: MarketsTokenModel)
}
