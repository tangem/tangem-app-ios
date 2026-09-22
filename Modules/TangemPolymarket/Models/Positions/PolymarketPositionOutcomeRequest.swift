//
//  PolymarketPositionOutcomeRequest.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketPositionOutcomeRequest: Hashable, Sendable {
    public let depositWalletAddress: String
    public let conditionId: String
    public let assetId: String

    public init(depositWalletAddress: String, conditionId: String, assetId: String) {
        self.depositWalletAddress = depositWalletAddress
        self.conditionId = conditionId
        self.assetId = assetId
    }
}
