//
//  CommonExpressApproveTransactionProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

struct CommonExpressApproveTransactionProcessor {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let transactionCreator: TransactionCreator
    private let transactionDispatcher: TransactionDispatcher

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        transactionCreator: TransactionCreator,
        transactionDispatcher: TransactionDispatcher
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.transactionCreator = transactionCreator
        self.transactionDispatcher = transactionDispatcher
    }
}

// MARK: - ExpressCEXTransactionProcessor

extension CommonExpressApproveTransactionProcessor: ExpressApproveTransactionProcessor {
    func process(data: ApproveTransactionData) async throws -> TransactionDispatcherResult {
        let transaction = try await buildTransaction(data: data)
        return try await transactionDispatcher.send(transaction: .express(.default(transaction)))
    }
}

// MARK: - Private

private extension CommonExpressApproveTransactionProcessor {
    func buildTransaction(data: ApproveTransactionData) async throws -> BSDKTransaction {
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0)
        let transaction = try await transactionCreator.createTransaction(
            amount: amount,
            fee: data.fee,
            destinationAddress: data.toContractAddress,
            contractAddress: data.toContractAddress,
            params: EthereumTransactionParams(data: data.txData)
        )

        return transaction
    }
}
