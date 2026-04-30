//
//  NewsIncomingLinkParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Parses news deeplinks in two supported formats:
///
/// 1. Universal Link (web-style):
///    `https://tangem.com/news/{category}/{id}-{slug}`
///    Example: `https://tangem.com/news/markets/190801-polygon-protiv-ethereum`
///
/// 2. Tangem scheme (app-style):
///    `tangem://news`                          — all categories
///    `tangem://news?category_id={categoryId}` — specific category
///    `tangem://news?id={articleId}`           — specific article
struct NewsIncomingLinkParser: IncomingActionURLParser {
    private let deeplinkValidator: DeeplinkValidator

    init(deeplinkValidator: DeeplinkValidator = CommonDeepLinkValidator()) {
        self.deeplinkValidator = deeplinkValidator
    }

    func parse(_ url: URL) throws -> IncomingAction? {
        if isUniversalNewsLink(url) {
            return parseUniversalLink(url)
        }

        if isNewsDeepLink(url) {
            return parseDeepLink(url)
        }

        return nil
    }
}

// MARK: - Format detection

private extension NewsIncomingLinkParser {
    func isUniversalNewsLink(_ url: URL) -> Bool {
        let urlString = url.absoluteString
        let prefix = IncomingActionConstants.tangemDomain + IncomingActionConstants.newsPath
        guard urlString.starts(with: prefix) else {
            return false
        }
        // Guard against `/newsletter` and similar lookalikes
        return url.pathComponents.count >= 2 && url.pathComponents[1].lowercased() == Constants.newsPathComponent
    }

    func isNewsDeepLink(_ url: URL) -> Bool {
        guard url.absoluteString.starts(with: IncomingActionConstants.universalLinkScheme) else {
            return false
        }
        return url.host?.lowercased() == IncomingActionConstants.DeeplinkDestination.news.rawValue
    }
}

// MARK: - Universal Link parsing

private extension NewsIncomingLinkParser {
    func parseUniversalLink(_ url: URL) -> IncomingAction? {
        let components = url.pathComponents
        // pathComponents: ["/", "news", "markets", "190801-polygon-slug"]
        guard components.count >= 4 else {
            return nil
        }

        let idSlugComponent = components[3]
        let idString: String
        if let dashIndex = idSlugComponent.firstIndex(of: "-") {
            idString = String(idSlugComponent[..<dashIndex])
        } else {
            idString = idSlugComponent
        }

        guard !idString.isEmpty, Int(idString) != nil else {
            return nil
        }

        return makeAction(url: url, destination: .newsArticle, id: idString, categoryId: nil)
    }
}

// MARK: - Deeplink parsing

private extension NewsIncomingLinkParser {
    func parseDeepLink(_ url: URL) -> IncomingAction? {
        let queryItems = url.getKeyedQueryItems()
        let id = queryItems[IncomingActionConstants.DeeplinkParams.id]
        let categoryId = queryItems[IncomingActionConstants.DeeplinkParams.categoryId]

        return makeAction(url: url, destination: .news, id: id, categoryId: categoryId)
    }
}

// MARK: - Action factory

private extension NewsIncomingLinkParser {
    func makeAction(
        url: URL,
        destination: IncomingActionConstants.DeeplinkDestination,
        id: String?,
        categoryId: String?
    ) -> IncomingAction? {
        let params = DeeplinkNavigationAction.Params(
            id: id,
            categoryId: categoryId
        )

        let action = DeeplinkNavigationAction(
            destination: destination,
            params: params,
            deeplinkString: url.absoluteString
        )

        guard deeplinkValidator.hasMinimumDataForHandling(deeplink: action) else {
            return nil
        }

        return .navigation(action)
    }
}

// MARK: - Constants

private extension NewsIncomingLinkParser {
    enum Constants {
        static let newsPathComponent = "news"
    }
}

// MARK: - Helpers

private extension URL {
    func getKeyedQueryItems() -> [String: String] {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .filter { $0.value?.isNotEmpty ?? false }
            .keyedFirst(by: \.name)
            .compactMapValues { $0.value?.removingPercentEncoding } ?? [:]
    }
}
