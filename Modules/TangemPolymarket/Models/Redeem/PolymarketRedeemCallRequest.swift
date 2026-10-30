//
//  PolymarketRedeemCallRequest.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketRedeemCallRequest: Hashable, Sendable {
    public let conditionId: String
    public let assetId: String
    public let isNegRisk: Bool
    public let version: PolymarketMarketVersion?

    public init(conditionId: String, assetId: String, isNegRisk: Bool, version: PolymarketMarketVersion?) {
        self.conditionId = conditionId
        self.assetId = assetId
        self.isNegRisk = isNegRisk
        self.version = version
    }

    public init(position: PolymarketPosition) {
        self.init(
            conditionId: position.conditionId,
            assetId: position.assetId,
            isNegRisk: position.isNegRisk,
            version: position.version
        )
    }
}
