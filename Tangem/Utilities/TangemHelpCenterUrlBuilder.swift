//
//  TangemHelpCenterUrlBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemHelpCenterUrlBuilder {
    func url(article: Article) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "tangem.com"
        components.path = "/en/help-center/\(article.path)/"
        components.queryItems = TangemUrlHelper.queryItems(utmCampaign: .articles)
        return components.url
    }
}

extension TangemHelpCenterUrlBuilder {
    enum Article {
        case howToSwapCoinsAndTokens
    }
}

private extension TangemHelpCenterUrlBuilder.Article {
    var path: String {
        switch self {
        case .howToSwapCoinsAndTokens:
            "tangem-wallet-core-functionality/how-to-swap-coins-and-tokens"
        }
    }
}
