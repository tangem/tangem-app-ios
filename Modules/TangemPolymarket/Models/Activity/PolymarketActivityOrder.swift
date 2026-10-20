//
//  PolymarketActivityOrder.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketActivityOrder: Hashable, Sendable {
    public let assetId: String
    public let averagePrice: Decimal
    public let platformFee: Decimal
    public let builderFee: Decimal
    public let notional: Decimal
    public let tradeCount: Int

    public var fee: Decimal { platformFee + builderFee }

    public init(
        assetId: String,
        averagePrice: Decimal,
        platformFee: Decimal,
        builderFee: Decimal,
        notional: Decimal,
        tradeCount: Int
    ) {
        self.assetId = assetId
        self.averagePrice = averagePrice
        self.platformFee = platformFee
        self.builderFee = builderFee
        self.notional = notional
        self.tradeCount = tradeCount
    }
}
