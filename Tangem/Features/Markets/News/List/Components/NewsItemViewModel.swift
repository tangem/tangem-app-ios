//
//  NewsItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

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
    let isRead: Bool
    let chips: [InfoChipItem]

    // MARK: - Init

    init(
        id: Int,
        score: String,
        category: String,
        relatedTokens: [RelatedToken],
        title: String,
        relativeTime: String,
        isTrending: Bool,
        newsUrl: String,
        isRead: Bool
    ) {
        self.id = id
        self.score = score
        self.category = category
        self.relatedTokens = relatedTokens
        self.title = title
        self.relativeTime = relativeTime
        self.isTrending = isTrending
        self.newsUrl = newsUrl
        self.isRead = isRead

        var chips: [InfoChipItem] = []
        if !category.isEmpty {
            chips.append(InfoChipItem(title: category))
        }
        chips += relatedTokens.map {
            InfoChipItem(id: $0.id, title: $0.symbol, leadingIcon: .url($0.iconURL))
        }
        self.chips = chips
    }

    // MARK: - Methods

    func withIsRead(_ isRead: Bool) -> NewsItemViewModel {
        NewsItemViewModel(
            id: id,
            score: score,
            category: category,
            relatedTokens: relatedTokens,
            title: title,
            relativeTime: relativeTime,
            isTrending: isTrending,
            newsUrl: newsUrl,
            isRead: isRead
        )
    }

    // MARK: - Nested Types

    struct RelatedToken: Identifiable {
        let id: String
        let symbol: String
        let iconURL: URL
    }
}
