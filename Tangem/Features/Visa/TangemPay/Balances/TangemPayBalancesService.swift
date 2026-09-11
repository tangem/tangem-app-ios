//
//  TangemPayBalancesService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayBalancesService: TangemPayBalancesProvider {
    var networks: [TangemPayBalance.Network] { get }

    func loadBalance() async
}

/// The account-wide providers use the hardcoded `TangemPayUtilities.usdcTokenItem`;
/// the per-token factories below use the account token's own item.
protocol TangemPayBalancesProvider {
    /// Total Tangem Pay balance as crypto currency from `TangemPayBalance.balance.crypto.balance`
    var totalTokenBalanceProvider: TokenBalanceProvider { get }

    /// Tangem Pay with `AppCurrency` fiat rate
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }

    /// Tangem Pay with constant fiat rate `1:1`
    var fixedFiatTotalTokenBalanceProvider: TokenBalanceProvider { get }

    /// Available Tangem Pay balance as crypto currency from `TangemPayBalance.availableForWithdrawal.amount`
    var availableBalanceProvider: TokenBalanceProvider { get }

    /// Available Tangem Pay balance as fiat currency from `TangemPayBalance.availableForWithdrawal.amount`
    var fiatAvailableBalanceProvider: TokenBalanceProvider { get }

    func availableBalanceProvider(for accountToken: TangemPayAccountToken) -> TokenBalanceProvider

    func fiatAvailableBalanceProvider(for accountToken: TangemPayAccountToken) -> TokenBalanceProvider
}
