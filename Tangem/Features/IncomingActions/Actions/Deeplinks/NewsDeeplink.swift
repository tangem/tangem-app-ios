//
//  NewsDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `tangem://news[?news_id|category_id]` — an article when it names one, otherwise the list.
struct NewsDeeplink: HostNamedDeeplink, Equatable {
    static let host = "news"

    let newsId: Int?
    let categoryId: Int?

    var action: DeeplinkNavigationAction { .news(self) }
}

// MARK: - Parsing

extension NewsDeeplink {
    private enum Keys {
        static let newsId = "news_id"
        static let categoryId = "category_id"
    }

    init(link: DeeplinkURL) throws {
        newsId = try link.query.optionalNumber(Keys.newsId)
        categoryId = try link.query.optionalNumber(Keys.categoryId)
    }
}
