//
//  MarketsCategoriesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol MarketsCategoriesProvider {
    func categories() async throws -> MarketsCategoriesSnapshot
}

struct MarketsCategoriesSnapshot: Equatable {
    let categories: [MarketsDTO.Categories.Category]
    /// The country `restricted` was evaluated for, or `nil` when geo could not be resolved.
    let country: String?

    var selectableCategories: [MarketsDTO.Categories.Category] {
        categories.filter { $0.code != MarketsCategoryCode.featuredAssets }
    }

    var featuredCategory: MarketsDTO.Categories.Category? {
        categories.first { $0.code == MarketsCategoryCode.featuredAssets }
    }

    /// The category every other one is a part of: what tells real assets from the rest of the market.
    var umbrellaCategory: MarketsDTO.Categories.Category? {
        selectableCategories.first { $0.code == MarketsCategoryCode.realWorldAssets }
    }
}
