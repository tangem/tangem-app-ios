//
//  PolymarketNetworkRowViewData.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets

public struct PolymarketNetworkRowViewData: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let icon: ImageType
    public let action: () -> Void

    public init(id: String, title: String, subtitle: String, icon: ImageType, action: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.action = action
    }
}
