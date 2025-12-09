//
//  TangemPayBalancesService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol TangemPayBalancesService: TangemPayBalancesProvider {
    func loadBalance() async
}

/// All balance's providers use hardcoded `TangemPayUtilities.usdcTokenItem`
protocol TangemPayBalancesProvider {
    /// Total Tangem Pay balance as crypto currency from `TangemPayBalance.balance.crypto.balance`
    var totalTokenBalanceProvider: TokenBalanceProvider { get }

    /// Tangem Pay with `AppCurrency` fiat rate
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }

    /// Tangem Pay with constant fiat rate `1:1`
    var fixedFiatTotalTokenBalanceProvider: TokenBalanceProvider { get }

    /// Available Tangem Pay balance as crypto currency from `TangemPayBalance.availableForWithdrawal.amount`
    var availableBalanceProvider: TokenBalanceProvider { get }
}
