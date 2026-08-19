//
//  PolymarketSeries.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketSeries: Hashable, Sendable {
    public let id: String
    public let label: String
    public let iconURL: URL?

    public init(id: String, label: String, iconURL: URL?) {
        self.id = id
        self.label = label
        self.iconURL = iconURL
    }
}
