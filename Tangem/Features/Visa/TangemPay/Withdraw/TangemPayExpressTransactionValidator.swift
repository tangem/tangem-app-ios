//
//  TangemPayExpressTransactionValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct TangemPayExpressTransactionValidator: ExpressTransactionValidator {
    let availableBalanceProvider: any TokenBalanceProvider

    func validate(amount: Amount, fee: Fee) throws {
        guard let balance = availableBalanceProvider.balanceType.value else {
            throw ValidationError.balanceNotFound
        }

        guard amount.value <= balance else {
            throw ValidationError.amountExceedsBalance
        }

        // All good
    }
}
