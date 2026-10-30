//
//  PolymarketCategory.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketCategory: Hashable, Sendable {
    public let id: Int
    public let label: String
    public let icon: PolymarketCategoryIcon?
    public let subcategories: [PolymarketCategory]
    public let filters: [PolymarketCategoryFilter]

    public init(
        id: Int,
        label: String,
        icon: PolymarketCategoryIcon?,
        subcategories: [PolymarketCategory] = [],
        filters: [PolymarketCategoryFilter] = []
    ) {
        self.id = id
        self.label = label
        self.icon = icon
        self.subcategories = subcategories
        self.filters = filters
    }
}
