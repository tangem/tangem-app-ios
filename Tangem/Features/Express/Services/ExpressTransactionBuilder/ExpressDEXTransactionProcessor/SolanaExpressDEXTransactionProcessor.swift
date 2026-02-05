//
//  SolanaExpressDEXTransactionProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

struct SolanaExpressDEXTransactionProcessor {
    let transactionDispatcher: any TransactionDispatcher
}

// MARK: - ExpressDEXTransactionProcessor

extension SolanaExpressDEXTransactionProcessor: ExpressDEXTransactionProcessor {
    func process(data: ExpressTransactionData, fee: Fee) async throws -> TransactionDispatcherResult {
        assert(data.transactionType == .swap, "Support only .swap transactions")

        let transaction = try await buildRawCompiledTransaction(data: data, fee: fee)
        return try await transactionDispatcher.send(transaction: .express(.compiled(transaction)))
    }
}

// MARK: - Private

private extension SolanaExpressDEXTransactionProcessor {
    func buildRawCompiledTransaction(data: ExpressTransactionData, fee: Fee) async throws -> Data {
        guard let txData = data.txData, let unsignedData = Data(base64Encoded: txData) else {
            throw ExpressDEXTransactionProcessorError.transactionDataForSwapOperationNotFound
        }

        return unsignedData
    }
}
