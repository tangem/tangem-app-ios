//
//  SolanaFeeParameters.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct SolanaFeeParameters: FeeParameters {
    public let computeUnitLimit: UInt32?
    public let computeUnitPrice: UInt64?
    public let accountCreationFee: Decimal

    public init(computeUnitLimit: UInt32?, computeUnitPrice: UInt64?, accountCreationFee: Decimal) {
        self.computeUnitLimit = computeUnitLimit
        self.computeUnitPrice = computeUnitPrice
        self.accountCreationFee = accountCreationFee
    }
}
