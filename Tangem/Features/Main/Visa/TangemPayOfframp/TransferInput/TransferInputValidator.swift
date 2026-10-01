//
//  TransferInputValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TransferInputValidator {
    static let minAmount: Decimal = 1
    static let maxAmount: Decimal = 10_000

    static func validate(amount: Decimal, available: Decimal) -> TransferInputAmountState {
        guard (minAmount ... maxAmount).contains(amount) else {
            return .outOfRange(min: minAmount, max: maxAmount)
        }

        return amount > available ? .notEnoughFunds : .valid
    }
}
