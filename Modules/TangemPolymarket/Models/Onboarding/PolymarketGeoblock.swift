//
//  PolymarketGeoblock.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketGeoblock: Hashable, Sendable {
    public let isBlocked: Bool
    public let country: String?
    public let region: String?

    public init(isBlocked: Bool, country: String?, region: String?) {
        self.isBlocked = isBlocked
        self.country = country
        self.region = region
    }
}
