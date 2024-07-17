//
//  TransactionInfo.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct TransactionInfo: Hashable {
    let id: String
    let actionId: String
    let network: String
    let type: TransactionType
    let status: TransactionStatus
    let unsignedTransactionData: Data
    let fee: Decimal
}
