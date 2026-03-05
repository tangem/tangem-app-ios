//
//  UnsupportedTransactionDispatcher.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct UnsupportedTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool { true }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        throw TransactionDispatcherProviderError.transactionNotSupported(reason: "Does not support \(transaction.rawCaseValue)")
    }
}
