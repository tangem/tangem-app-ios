//
//  PendingTransactionDetails.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct PendingTransactionDetails {
    let type: TransactionType
    let id: String

    enum TransactionType {
        case onramp
        case swap
    }
}
