//
//  P2PTransaction.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct P2PTransaction: StakingTransaction {
    public let amount: Amount
    public let fee: Fee
    public let unsignedData: EthereumCompiledTransactionData
    public let target: String? // vault

    public init(amount: Amount, fee: Fee, unsignedData: EthereumCompiledTransactionData, target: String?) {
        self.amount = amount
        self.fee = fee
        self.unsignedData = unsignedData
        self.target = target
    }
}
