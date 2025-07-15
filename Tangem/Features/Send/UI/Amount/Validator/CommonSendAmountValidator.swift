//
//  CommonSendAmountValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CommonSendAmountValidator {
    private let tokenItem: TokenItem
    private let validator: TransactionValidator

    init(tokenItem: TokenItem, validator: TransactionValidator) {
        self.tokenItem = tokenItem
        self.validator = validator
    }
}

extension CommonSendAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        guard amount > 0 else {
            throw SendAmountValidatorError.zeroAmount
        }

        let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
        try validator.validate(amount: amount)
    }
}
