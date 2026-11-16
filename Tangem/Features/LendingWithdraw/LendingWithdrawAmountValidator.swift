//
//  LendingWithdrawAmountValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct LendingWithdrawAmountValidator: SendAmountValidator {
    let availableToWithdraw: () -> Decimal

    func validate(amount: Decimal) throws {
        guard amount > 0 else {
            throw SendAmountValidatorError.zeroAmount
        }

        guard amount <= availableToWithdraw() else {
            throw ValidationError.amountExceedsBalance
        }
    }
}
