//
//  PolymarketOutcome.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketOutcome: Hashable, Sendable {
    public let assetId: String

    public let title: String

    public let probability: Decimal?

    public init(assetId: String, title: String, probability: Decimal?) {
        self.assetId = assetId
        self.title = title
        self.probability = probability
    }
}
