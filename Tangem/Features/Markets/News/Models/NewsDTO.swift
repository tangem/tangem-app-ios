//
//  NewsDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum NewsDTO {
    enum List {}
    enum Details {}
    enum Categories {}
    enum Like {}
}

// MARK: - List

extension NewsDTO.List {
    struct Request: Encodable {
        let page: Int
        let limit: Int
        let lang: String?
        let asOf: String?
        let categoryIds: [Int]?
        let tokenIds: [String]?

        init(
            page: Int = 1,
            limit: Int = 20,
            lang: String? = nil,
            asOf: String? = nil,
            categoryIds: [Int]? = nil,
            tokenIds: [String]? = nil
        ) {
            self.page = page
            self.limit = limit
            self.lang = lang
            self.asOf = asOf
            self.categoryIds = categoryIds
            self.tokenIds = tokenIds
        }

        var parameters: [String: Any] {
            var params: [String: Any] = [
                "page": page,
                "limit": limit,
            ]

            if let lang {
                params["lang"] = lang
            }

            if let asOf {
                params["asOf"] = asOf
            }

            if let categoryIds, !categoryIds.isEmpty {
                params["categoryIds"] = categoryIds.map { String($0) }.joined(separator: ",")
            }

            if let tokenIds, !tokenIds.isEmpty {
                params["tokenIds"] = tokenIds.joined(separator: ",")
            }

            return params
        }
    }

    struct Response: Decodable {
        let meta: Meta
        let items: [Item]
    }

    struct Meta: Decodable {
        let page: Int
        let limit: Int
        let total: Int
        let hasNext: Bool
        let asOf: String
    }

    struct Item: Decodable, Identifiable {
        let id: Int
        let createdAt: Date
        let score: Double
        let language: String
        let isTrending: Bool
        let categories: [Category]
        let relatedTokens: [RelatedToken]
        let title: String
        let newsUrl: String
    }

    struct Category: Decodable, Identifiable, Hashable {
        let id: Int
        let name: String
    }

    struct RelatedToken: Decodable, Hashable {
        let id: String
        let symbol: String
        let name: String
    }
}

// MARK: - Details

extension NewsDTO.Details {
    struct Request {
        let newsId: Int
        let lang: String?

        init(newsId: Int, lang: String? = nil) {
            self.newsId = newsId
            self.lang = lang
        }
    }

    struct Response: Decodable {
        let id: Int
        let createdAt: String
        let score: Double
        let language: String
        let isTrending: Bool
        let categories: [NewsDTO.List.Category]
        let relatedTokens: [NewsDTO.List.RelatedToken]
        let title: String
        let newsUrl: String
        let shortContent: String
        let content: String
        let originalArticles: [OriginalArticle]
    }

    struct OriginalArticle: Decodable, Identifiable {
        let id: Int
        let title: String?
        let sourceName: String?
        let language: String?
        let publishedAt: String?
        let url: String?
        let imageUrl: String?
    }
}

// MARK: - Categories

extension NewsDTO.Categories {
    struct Response: Decodable {
        let items: [Item]
    }

    struct Item: Decodable, Identifiable {
        let id: Int
        let name: String
    }
}

// MARK: - Like

extension NewsDTO.Like {
    struct Request: Encodable {
        let newsId: Int
        let isLiked: Bool

        enum CodingKeys: String, CodingKey {
            case isLiked
        }
    }

    struct Response: Decodable {
        let isLiked: Bool
    }
}

// MARK: - Trending

struct TrendingNewsResponse: Decodable {
    let items: [NewsDTO.List.Item]
}
