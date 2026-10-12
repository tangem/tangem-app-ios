//
//  NewsArticleDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// An article, asked for as the page `https://tangem.com/news/{category}/{id}-{slug}`. The link itself is
/// carried along because the news feature reports it for attribution.
struct NewsArticleDeeplink: Equatable {
    let newsId: Int
    let deeplinkString: String

    var action: DeeplinkNavigationAction { .newsArticle(self) }
}

// MARK: - PathNamedDeeplink

extension NewsArticleDeeplink: PathNamedDeeplink {
    static let pathSegment = "news"

    static func action(from link: DeeplinkURL) -> DeeplinkNavigationAction? {
        // Articles live on the main domain only; `/news` on its own is the section, not an article.
        guard case .path(IncomingActionConstants.tangemHost, let components) = link.kind, components.count >= 3 else {
            return nil
        }

        // The third component starts with the id, optionally followed by a dash and a slug.
        guard let newsId = DeeplinkRules.number(String(components[2].prefix(while: { $0 != "-" }))) else {
            return nil
        }

        return NewsArticleDeeplink(newsId: newsId, deeplinkString: link.absoluteString).action
    }
}
