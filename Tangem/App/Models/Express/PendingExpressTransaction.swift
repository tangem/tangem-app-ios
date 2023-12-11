//
//  PendingExpressTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PendingExpressTransaction: Equatable {
    let transactionRecord: ExpressPendingTransactionRecord
    let currentStatus: PendingExpressTransactionStatus
    let statuses: [PendingExpressTransactionStatus]
}
