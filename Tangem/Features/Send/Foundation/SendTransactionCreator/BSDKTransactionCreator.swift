//
//  BSDKTransactionCreator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct BSDKTransactionCreator: SendTransactionCreator {
    let transactionCreator: any BlockchainSdk.TransactionCreator

    func createTransaction(
        amount: Amount,
        fee: Fee,
        destinationAddress: String,
        params: TransactionParams?
    ) async throws -> BSDKTransaction {
        try await transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: destinationAddress,
            params: params
        )
    }
}
