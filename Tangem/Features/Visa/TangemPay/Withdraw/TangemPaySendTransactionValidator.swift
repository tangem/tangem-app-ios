//
//  TangemPaySendTransactionValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct TangemPaySendTransactionValidator: SendTransactionValidator {
    let availableBalanceProvider: any TokenBalanceProvider

    func validate(amount: Amount) throws {
        guard let balance = availableBalanceProvider.balanceType.value else {
            throw ValidationError.balanceNotFound
        }

        guard amount.value <= balance else {
            throw ValidationError.amountExceedsBalance
        }
    }

    func validate(amount: Amount, fee: Fee) throws {
        // TangemPay flows are fee-exempt for the user (see `isExemptFee` on the swapable token),
        // so client-side fee validation collapses to the amount-only check.
        try validate(amount: amount)
    }
}
