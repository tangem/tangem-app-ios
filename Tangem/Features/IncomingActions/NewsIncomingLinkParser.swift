//
//  NewsIncomingLinkParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Parses news Universal Links
/// Format: https://tangem.com/news/{category}/{id}-{slug}
/// Example: https://tangem.com/news/markets/190801-polygon-protiv-ethereum
struct NewsIncomingLinkParser: IncomingActionURLParser {
    private let deeplinkValidator: DeeplinkValidator

    init(deeplinkValidator: DeeplinkValidator = CommonDeepLinkValidator()) {
        self.deeplinkValidator = deeplinkValidator
    }

    func parse(_ url: URL) throws -> IncomingAction? {
        let urlString = url.absoluteString

        guard urlString.starts(with: IncomingActionConstants.tangemDomain + IncomingActionConstants.newsPath) else {
            return nil
        }

        return parseNewsLink(url)
    }

    private func parseNewsLink(_ url: URL) -> IncomingAction? {
        let components = url.pathComponents
        // pathComponents: ["/", "news", "markets", "190801-polygon-slug"]
        guard components.count >= 4,
              components[1].lowercased() == "news" else {
            return nil
        }

        // Extract id from "{id}-{slug}" format (component at index 3)
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

        let params = DeeplinkNavigationAction.Params(
            type: nil,
            name: nil,
            tokenId: nil,
            networkId: nil,
            userWalletId: nil,
            derivationPath: nil,
            transactionId: nil,
            promoCode: nil,
            url: nil,
            entry: nil,
            id: idString
        )

        let deeplinkNavAction = DeeplinkNavigationAction(
            destination: .news,
            params: params,
            deeplinkString: url.absoluteString
        )

        guard deeplinkValidator.hasMinimumDataForHandling(deeplink: deeplinkNavAction) else {
            return nil
        }

        return .navigation(deeplinkNavAction)
    }
}
