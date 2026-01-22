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

    func getCoinBalance() throws -> Decimal {
        // Basically the `TangemPay` don't have the crypto fee on the user side
        // Then all available balance can be consider as fee currency balance
        return try getBalance()
    }
}
