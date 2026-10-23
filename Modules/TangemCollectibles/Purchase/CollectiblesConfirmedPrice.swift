//
//  CollectiblesConfirmedPrice.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct CollectiblesConfirmedPrice: Sendable {
    public let amount: UInt64
    public let feeAmount: UInt64

    public init(amount: UInt64, feeAmount: UInt64) {
        self.amount = amount
        self.feeAmount = feeAmount
    }
}
