//
//  ExpressManagerRestriction.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressManagerRestriction {
    case permissionRequired(spender: String)
    case hasPendingTransaction
    case notEnoughAmountForSwapping
}
