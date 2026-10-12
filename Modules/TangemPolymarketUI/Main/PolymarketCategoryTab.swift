//
//  PolymarketCategoryTab.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

public struct PolymarketCategoryTab: TabNavigationItem {
    public let id: Int
    public let title: String

    public init(id: Int, title: String) {
        self.id = id
        self.title = title
    }
}
