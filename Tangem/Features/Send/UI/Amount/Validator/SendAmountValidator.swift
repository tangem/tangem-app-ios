//
//  SendAmountValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendAmountValidator {
    func validate(amount: Decimal) throws
}
