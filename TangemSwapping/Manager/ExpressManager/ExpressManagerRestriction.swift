//
//  ExpressManagerRestriction.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressManagerRestriction {
    case tooMinimalAmount(_ acceptableAmount: Decimal)
    case permissionRequired(spender: String)
    case hasPendingTransaction
    case notEnoughAmountForSwapping
}
