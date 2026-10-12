//
//  MarketsGeckoCategoriesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol MarketsGeckoCategoriesProvider {
    func categories() async throws -> MarketsGeckoCategoriesSnapshot
}

struct MarketsGeckoCategoriesSnapshot: Equatable {
    /// In the backend's order, which is by market cap descending.
    let categories: [MarketsDTO.GeckoCategories.Category]
    /// The country to send along with the filtered coin list so `restricted_for_country` gets filled;
    /// `nil` when geo could not be resolved.
    let country: String?
}
