//
//  CommonExpressCEXTransactionProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

struct CommonExpressCEXTransactionProcessor {
    private let tokenItem: TokenItem
    private let transactionCreator: TransactionCreator
    private let transactionDispatcher: TransactionDispatcher

    init(
        tokenItem: TokenItem,
        transactionCreator: TransactionCreator,
        transactionDispatcher: TransactionDispatcher
    ) {
        self.tokenItem = tokenItem
        self.transactionCreator = transactionCreator
        self.transactionDispatcher = transactionDispatcher
    }
}

// MARK: - ExpressCEXTransactionProcessor

extension CommonExpressCEXTransactionProcessor: ExpressCEXTransactionProcessor {
    func process(data: ExpressTransactionData, fee: BSDKFee) async throws -> TransactionDispatcherResult {
        assert(data.transactionType == .send, "Support only .send transactions")
        let transaction = try await buildTransaction(data: data, fee: fee)
        return try await transactionDispatcher.send(transaction: .express(.default(transaction)))
    }
}

// MARK: - Private

private extension CommonExpressCEXTransactionProcessor {
    func buildTransaction(data: ExpressTransactionData, fee: Fee) async throws -> BSDKTransaction {
        let transactionParams: TransactionParams? = try {
            if let extraDestinationId = data.extraDestinationId, !extraDestinationId.isEmpty {
                // If we received a extraId then try to map it to specific TransactionParams
                let builder = TransactionParamsBuilder(blockchain: tokenItem.blockchain)
                return try builder.transactionParameters(value: extraDestinationId)
            }

            return nil
        }()

        let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: data.txValue)
        let transaction = try await transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: data.destinationAddress,
            params: transactionParams
        )

        return transaction
    }
}
