//
//  BSDKExpressTransactionValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct BSDKExpressTransactionValidator: ExpressTransactionValidator {
    let transactionValidator: any TransactionValidator

    func validate(amount: Amount, fee: Fee) throws {
        try transactionValidator.validate(amount: amount, fee: fee)
    }
}
