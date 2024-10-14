//
//  TronTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct TronTransactionParams: TransactionParams {
    public let transactionType: TransactionType

    public init(transactionType: TransactionType) {
        self.transactionType = transactionType
    }
}

public extension TronTransactionParams {
    enum TransactionType {
        case transfer
        case approval(data: Data)
    }
}
