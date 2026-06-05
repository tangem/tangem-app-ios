//
//  BSDKTransactionValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct BSDKTransactionValidator: SendTransactionValidator {
    let transactionValidator: any BlockchainSdk.TransactionValidator

    func validate(amount: Amount) throws {
        try transactionValidator.validate(amount: amount)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try transactionValidator.validate(amount: amount, fee: fee)
    }
}
