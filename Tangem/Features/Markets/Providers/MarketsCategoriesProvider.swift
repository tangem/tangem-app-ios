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
}
