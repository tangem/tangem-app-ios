//
//  TronTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TronTransactionParams: TransactionParams {
    let transactionType: TransactionType

    init(transactionType: TransactionType) {
        self.transactionType = transactionType
    }
}

extension TronTransactionParams {
    enum TransactionType {
        case transfer
        case approval(data: Data)
    }
}
