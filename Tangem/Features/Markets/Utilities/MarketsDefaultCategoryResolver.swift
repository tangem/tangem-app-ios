//
//  MarketsDefaultCategoryResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

enum MarketsDefaultCategoryResolver {
    static func resolve(
        from categories: [MarketsDTO.Categories.Category],
        regionCode: String?
    ) -> MarketsDTO.Categories.Category? {
        let isCommoditiesRegion = regionCode
            .map { commoditiesRegionCodes.contains($0.uppercased()) } ?? false

        let preferredCode = isCommoditiesRegion ? MarketsCategoryCode.commodities : MarketsCategoryCode.realWorldAssets

        return categories.first { $0.code == preferredCode }
            ?? categories.first { $0.code == MarketsCategoryCode.realWorldAssets }
            ?? categories.sorted(by: \.displayOrder).first
    }

    /// The umbrella category is unrestricted here as well, but its xStocks and ETFs are blocked per coin, so it
    /// would open mostly greyed out.
    private static let commoditiesRegionCodes: Set<String> = ["US", "GB"]
}
