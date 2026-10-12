//
//  MarketsDTO+GeckoCategories.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension MarketsDTO {
    enum GeckoCategories {}
}

extension MarketsDTO.GeckoCategories {
    struct Request {
        /// Fiat code the backend converts `marketCap` into.
        let currency: String

        var parameters: [String: Any] {
            ["currency": currency]
        }
    }

    struct Response: Decodable {
        let categories: [Category]
    }

    /// A CoinGecko category ("tag" in product terms).
    struct Category: Identifiable, Codable, Hashable {
        /// CoinGecko slug, e.g. `layer-1`; the value `/coins/list` expects in `geckoCategoryId`.
        let id: String
        let name: String
        let marketCap: Decimal?
        let marketCapChange24h: Decimal?
        let featured: Bool
        let tokensCount: Int
    }
}
