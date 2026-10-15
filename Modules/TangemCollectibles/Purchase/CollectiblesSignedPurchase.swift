//
//  CollectiblesSignedPurchase.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct CollectiblesSignedPurchase: Sendable {
    public let signature: String

    let amount: UInt64
    let feeAmount: UInt64
    let serializedTransaction: Data
    let blockhashFetchedAt: Date
}
