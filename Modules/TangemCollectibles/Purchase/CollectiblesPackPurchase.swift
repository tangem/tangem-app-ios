//
//  CollectiblesPackPurchase.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct CollectiblesPackPurchase: Sendable {
    public let memo: String
    public let usdcMint: String
    public let amount: UInt64
    public let feeAmount: UInt64

    public init(memo: String, usdcMint: String, amount: UInt64, feeAmount: UInt64) {
        self.memo = memo
        self.usdcMint = usdcMint
        self.amount = amount
        self.feeAmount = feeAmount
    }
}
