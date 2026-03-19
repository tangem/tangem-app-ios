//
//  ApproveTransactionData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct ApproveTransactionData: Hashable {
    public let txData: Data
    public let spender: String
    public let toContractAddress: String

    public init(txData: Data, spender: String, toContractAddress: String) {
        self.txData = txData
        self.spender = spender
        self.toContractAddress = toContractAddress
    }
}
