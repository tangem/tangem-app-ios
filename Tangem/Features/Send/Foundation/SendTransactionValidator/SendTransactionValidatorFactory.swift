//
//  SendTransactionValidatorFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct SendTransactionValidatorFactory {
    let blockchain: Blockchain
    let transactionValidator: any BlockchainSdk.TransactionValidator

    func makeValidator() -> any SendTransactionValidator {
        if blockchain.isPsbtDexSwapSupported {
            return PsbtSwapTransactionValidator(transactionValidator: transactionValidator)
        }

        return BSDKTransactionValidator(transactionValidator: transactionValidator)
    }
}
