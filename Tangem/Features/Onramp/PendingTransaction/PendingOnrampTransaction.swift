//
//  PendingOnrampTransaction.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PendingOnrampTransaction: Equatable {
    let transactionRecord: OnrampPendingTransactionRecord
    let statuses: [PendingExpressTransactionStatus]
}

// MARK: - Identifiable protocol conformance

extension PendingOnrampTransaction: Identifiable {
    var id: String {
        transactionRecord.id
    }
}

// MARK: - Convenience extensions

extension PendingOnrampTransaction {
    var pendingTransaction: PendingTransaction {
        PendingTransaction(
            type: .onramp(
                sourceAmount: transactionRecord.fromAmount,
                sourceCurrencySymbol: transactionRecord.fromCurrencyCode,
                destination: transactionRecord.destinationTokenTxInfo
            ),
            expressTransactionId: transactionRecord.expressTransactionId,
            externalTxId: transactionRecord.externalTxId,
            externalTxURL: transactionRecord.externalTxURL,
            provider: transactionRecord.provider,
            date: transactionRecord.date,
            transactionStatus: transactionRecord.transactionStatus,
            refundedTokenItem: nil,
            statuses: statuses,
            averageDuration: nil,
            createdAt: nil
        )
    }
}
