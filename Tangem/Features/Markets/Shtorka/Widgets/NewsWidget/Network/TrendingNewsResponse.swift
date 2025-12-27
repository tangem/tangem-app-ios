//
//  TrendingNewsResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - TrendingNewsResponse

struct TrendingNewsResponse: Codable {
    let items: [Item]
}

extension TrendingNewsResponse {
    struct Item: Codable {
        let id: Int
        let createdAt: Date
        let score: Double
        let language: String?
        let isTrending: Bool
        let newsUrl: String
        let categories: [NewsCategory]
        let relatedTokens: [RelatedToken]
        let title: String
    }
}

// MARK: - NewsCategory

struct NewsCategory: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
}

// MARK: - RelatedToken

struct RelatedToken: Identifiable, Codable, Hashable {
    let id: String
    let symbol: String
    let name: String
}

// MARK: - JSONDecoder Extension

public extension JSONDecoder {
    static var trendingNewsDecoder: JSONDecoder {
        let decoder = JSONDecoder()

        // DateFormatter supporting ISO8601 with milliseconds and 'Z' suffix
        // Format: "2025-12-17T02:31:03.359Z"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
