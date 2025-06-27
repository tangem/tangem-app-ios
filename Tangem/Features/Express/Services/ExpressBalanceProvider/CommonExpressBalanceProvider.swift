//
//  CommonExpressBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct CommonExpressBalanceProvider {
    private let tokenItem: TokenItem
    private let availableBalanceProvider: TokenBalanceProvider
    private let feeProvider: WalletModelFeeProvider

    init(
        tokenItem: TokenItem,
        availableBalanceProvider: TokenBalanceProvider,
        feeProvider: WalletModelFeeProvider
    ) {
        self.tokenItem = tokenItem
        self.availableBalanceProvider = availableBalanceProvider
        self.feeProvider = feeProvider
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

    func getFeeCurrencyBalance() -> Decimal {
        feeProvider.getFeeCurrencyBalance(amountType: tokenItem.amountType)
    }
}
