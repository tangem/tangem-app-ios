//
//  LegacyTransactionRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

struct LegacyTransactionRecord: Hashable, Identifiable {
    var id: Int { hashValue }

    let amountType: Amount.AmountType
    let destination: String
    let timeFormatted: String
    var date: Date?
    let transferAmount: String
    let transactionType: TransactionType
    let status: Status
}

extension LegacyTransactionRecord {
    enum TransactionType: Hashable {
        case receive
        case send
    }

    enum Status {
        case inProgress
        case confirmed
    }
}
