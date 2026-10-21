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

    public init(id: Int, label: String, icon: PolymarketCategoryIcon?) {
        self.id = id
        self.label = label
        self.icon = icon
    }
}
