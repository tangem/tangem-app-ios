//
//  PolymarketUSDBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct PolymarketUSDBalanceProvider: TokenBalanceProvider {
    let collateralBalanceProvider: TokenBalanceProvider

    var balanceType: TokenBalanceType {
        collateralBalanceProvider.balanceType
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        collateralBalanceProvider.balanceTypePublisher
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        PolymarketFormattedBalance.money(balanceType)
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceTypePublisher
            .map(PolymarketFormattedBalance.money)
            .eraseToAnyPublisher()
    }
}
