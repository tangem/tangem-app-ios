//
//  PendingTransaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct PendingTransaction {
    let hash: String
    var destination: String
    let value: Decimal
    var source: String
    let fee: Decimal?
    let date: Date
    let isIncoming: Bool

    let transactionParams: TransactionParams?
}
