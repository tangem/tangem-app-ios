//
//  TangemPayExpressCEXTransactionProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

// Add implementation
// [REDACTED_TODO_COMMENT]
struct TangemPayExpressCEXTransactionProcessor {}

// MARK: - ExpressCEXTransactionProcessor

extension TangemPayExpressCEXTransactionProcessor: ExpressCEXTransactionProcessor {
    func process(data: ExpressTransactionData, fee: BSDKFee) async throws -> TransactionDispatcherResult {
        throw TransactionDispatcherResult.Error.transactionNotFound
    }
}
