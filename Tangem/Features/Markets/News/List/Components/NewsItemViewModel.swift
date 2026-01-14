//
//  NewsItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class NewsItemViewModel: Identifiable {
    // MARK: - Properties

    let id: Int
    let score: String
    let category: String
    let relatedTokens: [RelatedToken]
    let title: String
    let relativeTime: String
    let isTrending: Bool
    let newsUrl: String

    // MARK: - Init

    init(
        id: Int,
        score: String,
        category: String,
        relatedTokens: [RelatedToken],
        title: String,
        relativeTime: String,
        isTrending: Bool,
        newsUrl: String
    ) {
        self.id = id
        self.score = score
        self.category = category
        self.relatedTokens = relatedTokens
        self.title = title
        self.relativeTime = relativeTime
        self.isTrending = isTrending
        self.newsUrl = newsUrl
    }

    // MARK: - Nested Types

    struct RelatedToken: Identifiable {
        let id: String
        let symbol: String

        var iconURL: URL {
            IconURLBuilder().tokenIconURL(id: id, size: .small)
        }
    }
}
