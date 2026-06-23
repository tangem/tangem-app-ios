//
//  _TransactionHistoryDataMerger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

// [REDACTED_TODO_COMMENT]
struct _TransactionHistoryDataMerger {
    private static let activeExchangeTransactionStatuses: Set<ExpressTransactionStatus> = [
        /* .preview, */ // [REDACTED_TODO_COMMENT]
        .created,
        .unknown,
        .exchangeTxSent,
        .waiting,
        .waitingTxHash,
        .confirming,
        .exchanging,
        .sending,
        .verifying,
        .failed,
    ]

    private static let activeOnrampTransactionStatuses: Set<OnrampTransactionStatus> = [
        .created,
        .waitingForPayment,
        .paymentProcessing,
        .verifying,
        .paid,
        .sending,
    ]

    func merge(
        bsdkTransactions: [TransactionRecord],
        exchangeTransactions: [ExchangeTransaction],
        onrampTransactions: [OnrampTransaction]
    ) -> [TransactionRecord] {
        var bsdkTransactionsGroupedByHash: [String?: [TransactionRecord]] = bsdkTransactions.grouped(by: \.hash)
        var output: [TransactionRecord] = []

        for exchangeTransaction in exchangeTransactions {
            // Step 1: Deterministic mapping
            if let bsdkTransactions = bsdkTransactionsGroupedByHash.removeValue(forKey: exchangeTransaction.payIn.hash)
                ?? bsdkTransactionsGroupedByHash.removeValue(forKey: exchangeTransaction.payOut.hash) {
                output.append(contentsOf: bsdkTransactions.map { $0.withExtraInfo(.exchange(exchangeTransaction)) })
                continue
            }

            // Step 2: Heuristic mapping
            // [REDACTED_TODO_COMMENT]

            // Step 3: Add synthetic transaction if needed
            if canAddSyntheticTransaction(from: exchangeTransaction) {
                output.append(makeSyntheticTransaction(from: exchangeTransaction))
            }
        }

        for onrampTransaction in onrampTransactions {
            // Step 1: Deterministic mapping
            if let bsdkTransactions = bsdkTransactionsGroupedByHash.removeValue(forKey: onrampTransaction.payOut.hash) {
                output.append(contentsOf: bsdkTransactions.map { $0.withExtraInfo(.onramp(onrampTransaction)) })
                continue
            }

            // Step 2: Heuristic mapping
            // [REDACTED_TODO_COMMENT]

            // Step 3: Add synthetic transaction if needed
            if canAddSyntheticTransaction(from: onrampTransaction) {
                output.append(makeSyntheticTransaction(from: onrampTransaction))
            }
        }

        // Adding remaining BSDK transactions that were not enriched with exchange or onramp info
        for bsdkTransactions in bsdkTransactionsGroupedByHash {
            output.append(contentsOf: bsdkTransactions.value)
        }

        // [REDACTED_TODO_COMMENT]
        return output
    }

    private func canAddSyntheticTransaction(from exchangeTransaction: ExchangeTransaction) -> Bool {
        Self.activeExchangeTransactionStatuses.contains(exchangeTransaction.status)
    }

    private func canAddSyntheticTransaction(from onrampTransaction: OnrampTransaction) -> Bool {
        Self.activeOnrampTransactionStatuses.contains(onrampTransaction.status)
    }

    private func makeSyntheticTransaction(from exchangeTransaction: ExchangeTransaction) -> TransactionRecord {
        fatalError("Not implemented yet")
    }

    private func makeSyntheticTransaction(from onrampTransaction: OnrampTransaction) -> TransactionRecord {
        fatalError("Not implemented yet")
    }
}
