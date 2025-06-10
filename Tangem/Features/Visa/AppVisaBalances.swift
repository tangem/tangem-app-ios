//
//  AppVisaBalances.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

struct AppVisaBalances {
    let totalBalance: Decimal?
    let verifiedBalance: Decimal?
    let available: Decimal?
    let blocked: Decimal?
    let debt: Decimal?

    init(balances: VisaBalances) {
        totalBalance = balances.totalBalance
        verifiedBalance = balances.verifiedBalance
        available = balances.available
        blocked = balances.blocked
        debt = balances.debt
    }

    init(
        totalBalance: Decimal?,
        verifiedBalance: Decimal?,
        available: Decimal?,
        blocked: Decimal?,
        debt: Decimal?
    ) {
        self.totalBalance = totalBalance
        self.verifiedBalance = verifiedBalance
        self.available = available
        self.blocked = blocked
        self.debt = debt
    }
}
