//
//  TangemPayTransactionCreator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct TangemPayTransactionCreator: SendTransactionCreator {
    let sourceAddress: String
    let transactionValidator: any SendTransactionValidator

    func createTransaction(
        amount: Amount,
        fee: Fee,
        destinationAddress: String,
        params: TransactionParams?
    ) async throws -> BSDKTransaction {
        try transactionValidator.validate(amount: amount, fee: fee)

        return BSDKTransaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: sourceAddress,
            contractAddress: nil,
            params: params
        )
    }
}
