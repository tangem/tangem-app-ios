//
//  ExpressDEXTransactionProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

protocol ExpressDEXTransactionProcessor {
    func process(data: ExpressTransactionData, fee: BSDKFee) async throws -> TransactionDispatcherResult
}

enum ExpressDEXTransactionProcessorError: LocalizedError {
    case transactionDataForSwapOperationNotFound
}
