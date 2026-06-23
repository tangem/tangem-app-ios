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
    func merge(
        bsdkTransactions: [TransactionRecord],
        exchangeTransactions: [ExchangeTransaction],
        onrampTransactions: [OnrampTransaction]
    ) -> [TransactionRecord] {
        let bsdkTransactionsGroupedByHash: [String?: [TransactionRecord]] = bsdkTransactions.grouped(by: \.hash)
        var handledBSDKTransactionsTombstone: Set<String?> = []
        var output: [TransactionRecord] = []

        for exchangeTransaction in exchangeTransactions {
            // Deterministic mapping
            if let bsdkTransactions = bsdkTransactionsGroupedByHash[exchangeTransaction.payIn.hash]
                ?? bsdkTransactionsGroupedByHash[exchangeTransaction.payOut.hash] {
                output.append(contentsOf: bsdkTransactions.map { $0.withExtraInfo(.exchange(exchangeTransaction)) })
                // Safe to access [0] here since grouping guarantees at least one element
                handledBSDKTransactionsTombstone.insert(bsdkTransactions[0].hash)
                continue
            }

            // Heuristic mapping
            // [REDACTED_TODO_COMMENT]
        }

        for onrampTransaction in onrampTransactions {
            // Deterministic mapping
            if let bsdkTransactions = bsdkTransactionsGroupedByHash[onrampTransaction.payOut.hash] {
                output.append(contentsOf: bsdkTransactions.map { $0.withExtraInfo(.onramp(onrampTransaction)) })
                // Safe to access [0] here since grouping guarantees at least one element
                handledBSDKTransactionsTombstone.insert(bsdkTransactions[0].hash)
                continue
            }

            // Heuristic mapping
            // [REDACTED_TODO_COMMENT]
        }

        // Adding remaining BSDK transactions that were not enriched with exchange or onramp info
        for bsdkTransactions in bsdkTransactionsGroupedByHash where !handledBSDKTransactionsTombstone.contains(bsdkTransactions.key) {
            output.append(contentsOf: bsdkTransactions.value)
        }

        // [REDACTED_TODO_COMMENT]
        return output
    }
}
