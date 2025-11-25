//
//  TangemPayExpressBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct TangemPayExpressBalanceProvider: ExpressBalanceProvider {
    let availableBalanceProvider: TokenBalanceProvider

    func getBalance() throws -> Decimal {
        guard let balanceValue = availableBalanceProvider.balanceType.value else {
            throw ExpressBalanceProviderError.balanceNotFound
        }

        return balanceValue
    }

    func getFeeCurrencyBalance() -> Decimal {
        // Add implementation how many fee user have.
        // [REDACTED_TODO_COMMENT]
        return availableBalanceProvider.balanceType.value ?? 0
    }
}
