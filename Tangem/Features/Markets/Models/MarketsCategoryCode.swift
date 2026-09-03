//
//  MarketsCategoryCode.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Category slugs the app has to recognise by name. Ids are assigned per environment and differ between dev and
/// production, so everything that pins a specific category matches on `code`.
enum MarketsCategoryCode {
    static let realWorldAssets = "real-world-assets"
    static let commodities = "commodities"
}
