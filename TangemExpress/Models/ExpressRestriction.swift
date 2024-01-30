//
//  ExpressRestriction.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressRestriction {
    case tooSmallAmount(_ minAmount: Decimal)
    case approveTransactionInProgress(spender: String)
    case insufficientBalance(_ requiredAmount: Decimal)
    case notEnoughBalanceForFee
}
