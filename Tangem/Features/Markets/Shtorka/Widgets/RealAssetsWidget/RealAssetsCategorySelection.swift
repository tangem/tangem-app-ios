//
//  RealAssetsCategorySelection.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct RealAssetsCategorySelection: Hashable {
    let category: MarketsDTO.Categories.Category
    let sector: MarketsDTO.Categories.Sector?

    init(category: MarketsDTO.Categories.Category, sector: MarketsDTO.Categories.Sector? = nil) {
        self.category = category
        self.sector = sector
    }

    var isUmbrella: Bool {
        category.code == MarketsCategoryCode.realWorldAssets && sector == nil
    }

    var title: String {
        if let sector {
            return MarketsCategoryLocalizer.title(for: sector, in: category)
        }

        return MarketsCategoryLocalizer.title(for: category)
    }
}

struct RealAssetsCategoryFilterInput {
    let categories: [MarketsDTO.Categories.Category]
    let selection: RealAssetsCategorySelection
    let defaultSelection: RealAssetsCategorySelection
    let onApply: (RealAssetsCategorySelection) -> Void
}
