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
    let statuses: [PendingExpressTransactionStatus]
}

// MARK: - Identifiable protocol conformance

extension PendingExpressTransaction: Identifiable {
    var id: String {
        transactionRecord.expressTransactionId
    }
}

// MARK: - Convenience extensions

extension PendingExpressTransaction {
    var pendingTransaction: PendingTransaction {
        PendingTransaction(
            type: .swap(
                source: transactionRecord.sourceTokenTxInfo,
                destination: transactionRecord.destinationTokenTxInfo
            ),
            expressTransactionId: transactionRecord.expressTransactionId,
            externalTxId: transactionRecord.externalTxId,
            externalTxURL: transactionRecord.externalTxURL,
            provider: transactionRecord.provider,
            date: transactionRecord.date,
            transactionStatus: transactionRecord.transactionStatus,
            refundedTokenItem: transactionRecord.refundedTokenItem,
            statuses: statuses,
            averageDuration: transactionRecord.averageDuration,
            createdAt: transactionRecord.createdAt
        )
    }
}
