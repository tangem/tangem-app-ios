//
//  NewsItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class NewsItemViewModel: Identifiable, ObservableObject {
    // MARK: - Properties

    let id: Int
    let score: String
    let category: String
    let relatedTokens: [RelatedToken]
    let title: String
    let relativeTime: String
    let isTrending: Bool
    let newsUrl: String
    @Published var isRead: Bool

    // MARK: - Init

    init(from item: NewsDTO.List.Item, dateFormatter: NewsDateFormatter, isRead: Bool = false) {
        id = item.id
        score = String(format: "%.1f", item.score)
        category = item.categories.first?.name ?? ""
        relatedTokens = item.relatedTokens.map { RelatedToken(id: $0.id, symbol: $0.symbol) }
        title = item.title
        relativeTime = dateFormatter.formatRelativeTime(from: item.createdAt)
        isTrending = item.isTrending
        newsUrl = item.newsUrl
        self.isRead = isRead
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
