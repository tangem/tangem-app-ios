//
//  NFTSendAmountValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct NFTSendAmountValidator: SendAmountValidator {
    private let expectedAmount: Decimal

    init(expectedAmount: Decimal) {
        self.expectedAmount = expectedAmount
    }

    func validate(amount: Decimal) throws {
        if amount != expectedAmount {
            throw ValidationError.invalidAmount
        }
    }
}
