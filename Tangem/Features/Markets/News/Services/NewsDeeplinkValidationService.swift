//
//  NewsDeeplinkValidationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol NewsDeeplinkValidating {
    func setDeeplinkURL(_ url: String?)
    func validateAndLogMismatchIfNeeded(newsId: Int, actualNewsURL: String)
    func logMismatchOnError(newsId: Int, error: Error)
}

final class NewsDeeplinkValidationService: NewsDeeplinkValidating {
    private var pendingDeeplinkURL: String?

    func setDeeplinkURL(_ url: String?) {
        pendingDeeplinkURL = url
    }

    func validateAndLogMismatchIfNeeded(newsId: Int, actualNewsURL: String) {
        guard let deeplinkURL = pendingDeeplinkURL else { return }

        pendingDeeplinkURL = nil

        guard let deeplinkComponents = parseNewsURLComponents(deeplinkURL),
              let actualComponents = parseNewsURLComponents(actualNewsURL) else {
            return
        }

        let categoryMismatch = deeplinkComponents.category != actualComponents.category
        let slugMismatch = deeplinkComponents.slug != actualComponents.slug

        guard categoryMismatch || slugMismatch else { return }

        Analytics.log(
            event: .newsLinkMismatch,
            params: [
                .newsId: String(newsId),
                .source: deeplinkURL,
            ]
        )
    }

    func logMismatchOnError(newsId: Int, error: Error) {
        guard let deeplinkURL = pendingDeeplinkURL else { return }

        pendingDeeplinkURL = nil

        var params = error.marketsAnalyticsParams
        params[.newsId] = String(newsId)
        params[.source] = deeplinkURL

        Analytics.log(event: .newsLinkMismatch, params: params)
    }

    private func parseNewsURLComponents(_ urlString: String) -> NewsURLComponents? {
        guard let url = URL(string: urlString) else { return nil }

        let pathComponents = url.pathComponents
        // Format: ["/" , "news", "{category}", "{id}-{slug}"]
        guard pathComponents.count >= 4,
              pathComponents[1] == "news" else {
            return nil
        }

        let category = pathComponents[2]
        let idSlugComponent = pathComponents[3]

        // Extract slug from "{id}-{slug}" format
        guard let dashIndex = idSlugComponent.firstIndex(of: "-") else {
            // No slug in URL
            return NewsURLComponents(category: category, slug: nil)
        }

        let slug = String(idSlugComponent[idSlugComponent.index(after: dashIndex)...])
        return NewsURLComponents(category: category, slug: slug.nilIfEmpty)
    }
}

// MARK: - NewsURLComponents

extension NewsDeeplinkValidationService {
    private struct NewsURLComponents {
        let category: String
        let slug: String?
    }
}

// MARK: - Dependency injection

private struct NewsDeeplinkValidationServiceKey: InjectionKey {
    static var currentValue: NewsDeeplinkValidating = NewsDeeplinkValidationService()
}

extension InjectedValues {
    var newsDeeplinkValidationService: NewsDeeplinkValidating {
        get { Self[NewsDeeplinkValidationServiceKey.self] }
        set { Self[NewsDeeplinkValidationServiceKey.self] = newValue }
    }
}
