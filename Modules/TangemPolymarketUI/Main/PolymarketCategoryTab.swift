//
//  PolymarketCategoryTab.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemUI

public struct PolymarketCategoryTab: TabNavigationItem {
    public let id: Int
    public let title: String
    public let icon: ImageType?

    public init(id: Int, title: String, icon: ImageType? = nil) {
        self.id = id
        self.title = title
        self.icon = icon
    }
}
