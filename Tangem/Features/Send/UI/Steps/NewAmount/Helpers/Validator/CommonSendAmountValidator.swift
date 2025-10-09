//
//  CommonSendAmountValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CommonSendAmountValidator {
    private weak var input: SendSourceTokenInput?

    init(input: SendSourceTokenInput) {
        self.input = input
    }
}

extension CommonSendAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        guard let sourceToken = input?.sourceToken else {
            throw Error.sendSourceTokenInputNotFound
        }

        guard amount > 0 else {
            throw SendAmountValidatorError.zeroAmount
        }

        let amount = Amount(with: sourceToken.tokenItem.blockchain, type: sourceToken.tokenItem.amountType, value: amount)
        try sourceToken.transactionValidator.validate(amount: amount)
    }
}

extension CommonSendAmountValidator {
    enum Error: LocalizedError {
        case sendSourceTokenInputNotFound
    }
}
