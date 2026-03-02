//
//  CommonSwapAmountValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CommonSwapAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        // We don't validate amount in step. Amount will be validated after loading `/quotes`
    }
}
