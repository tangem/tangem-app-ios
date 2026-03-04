//
//  CommonExpressBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct CommonExpressBalanceProvider {
    private let availableBalanceProvider: TokenBalanceProvider
    private let feeBalanceProvider: TokenBalanceProvider

    init(
        availableBalanceProvider: TokenBalanceProvider,
        feeBalanceProvider: TokenBalanceProvider
    ) {
        self.availableBalanceProvider = availableBalanceProvider
        self.feeBalanceProvider = feeBalanceProvider
    }
}

// MARK: - ExpressBalanceProvider

extension CommonExpressBalanceProvider: ExpressBalanceProvider {
    func getBalance() throws -> Decimal {
        guard let balanceValue = availableBalanceProvider.balanceType.value else {
            throw ExpressBalanceProviderError.balanceNotFound
        }

        return balanceValue
    }

    func getCoinBalance() throws -> Decimal {
        guard let balanceValue = feeBalanceProvider.balanceType.value else {
            throw ExpressBalanceProviderError.balanceNotFound
        }

        return balanceValue
    }
}
