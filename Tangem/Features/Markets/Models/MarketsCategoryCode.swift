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
    static let xstocks = "xstocks"
    static let etfs = "etfs"
    static let commodities = "commodities"
    static let bonds = "bonds"
    static let stablecoins = "stablecoins"
    static let featuredAssets = "featured-assets"

    enum Sector: String {
        case technology
        case financials
        case healthcare
        case consumer
        case communication
        case crypto
        case industrials
        case energy
    }
}
