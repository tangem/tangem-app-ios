//
//  ApproveTransactionData.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct ApproveTransactionData: Hashable {
    public let txData: Data
    public let spender: String
    public let toContractAddress: String
    public let amountRaw: BigUInt

    public init(txData: Data, spender: String, toContractAddress: String, amountRaw: BigUInt) {
        self.txData = txData
        self.spender = spender
        self.toContractAddress = toContractAddress
        self.amountRaw = amountRaw
    }
}
