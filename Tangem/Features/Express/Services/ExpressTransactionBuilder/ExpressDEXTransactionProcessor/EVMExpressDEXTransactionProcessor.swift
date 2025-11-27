//
//  EVMExpressDEXTransactionProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

struct EVMExpressDEXTransactionProcessor {
    let feeTokenItem: TokenItem
    let transactionCreator: TransactionCreator
    let transactionDispatcher: TransactionDispatcher
}

// MARK: - ExpressDEXTransactionProcessor

extension EVMExpressDEXTransactionProcessor: ExpressDEXTransactionProcessor {
    func process(data: ExpressTransactionData, fee: Fee) async throws -> TransactionDispatcherResult {
        assert(data.transactionType == .swap, "Support only .swap transactions")

        let transaction = try await buildTransaction(data: data, fee: fee)
        return try await transactionDispatcher.send(transaction: .express(.default(transaction)))
    }
}

// MARK: - Private

private extension EVMExpressDEXTransactionProcessor {
    func buildTransaction(data: ExpressTransactionData, fee: Fee) async throws -> BSDKTransaction {
        guard let txData = data.txData else {
            throw ExpressDEXTransactionProcessorError.transactionDataForSwapOperationNotFound
        }

        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: data.txValue)
        let transaction = try await transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: data.destinationAddress,
            contractAddress: data.destinationAddress,
            // In EVM-like blockchains we should add the txData to the transaction
            params: EthereumTransactionParams(data: Data(hexString: txData))
        )

        return transaction
    }
}
