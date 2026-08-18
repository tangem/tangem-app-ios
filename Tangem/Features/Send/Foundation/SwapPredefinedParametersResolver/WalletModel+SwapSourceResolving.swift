//
//  WalletModel+SwapSourceResolving.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension WalletModel {
    /// The fiat available balance as currently loaded; zero while loading or without a known rate.
    var fiatAvailableBalance: Decimal {
        fiatAvailableBalanceProvider.balanceType.value ?? 0
    }
}

extension Array where Element == any WalletModel {
    /// The first (in UI order) wallet model holding the largest positive fiat balance,
    /// or `nil` when nothing is funded.
    var mostFiatFunded: (any WalletModel)? {
        var best: (any WalletModel)?
        var bestFiat: Decimal = 0

        for model in self {
            let fiat = model.fiatAvailableBalance
            if fiat > bestFiat {
                bestFiat = fiat
                best = model
            }
        }

        return best
    }
}
