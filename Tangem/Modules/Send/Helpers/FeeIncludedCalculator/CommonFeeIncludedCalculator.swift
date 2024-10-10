//
//  CommonFeeIncludedCalculator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdkLocal

struct CommonFeeIncludedCalculator: FeeIncludedCalculator {
    private let validator: TransactionValidator

    init(validator: TransactionValidator) {
        self.validator = validator
    }

    func shouldIncludeFee(_ fee: Fee, into amount: Amount) -> Bool {
        guard fee.amount.type == amount.type, amount >= fee.amount else {
            return false
        }

        do {
            try validator.validate(amount: amount, fee: fee)
            return false
        } catch ValidationError.totalExceedsBalance {
            return true
        } catch {
            return false
        }
    }
}
