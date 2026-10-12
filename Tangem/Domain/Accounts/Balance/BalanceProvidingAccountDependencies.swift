//
//  BalanceProvidingAccountDependencies.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The dependencies an account's balance and rates are read off, whichever kind of account they were built for.
protocol BalanceProvidingAccountDependencies {
    var walletModelsManager: WalletModelsManager { get }
    var derivationManager: (DerivationManager & DerivationStatusProvider)? { get }
}

extension BalanceProvidingAccountDependencies {
    func makeBalanceProvidingDependencies() -> (
        balanceProvider: AccountBalanceProvider,
        ratesProvider: AccountRateProvider
    ) {
        let totalBalanceProvider = WalletModelsTotalBalanceProvider(
            walletModelsManager: walletModelsManager,
            analyticsLogger: AccountTotalBalanceProviderAnalyticsLogger(),
            derivationStatusProvider: derivationManager
        )

        let commonBalanceProvider = CommonAccountBalanceProvider(
            totalBalanceProvider: totalBalanceProvider
        )

        let commonRatesProvider = CommonAccountRateProvider(
            walletModelsManager: walletModelsManager,
            totalBalanceProvider: totalBalanceProvider
        )

        return (commonBalanceProvider, commonRatesProvider)
    }
}
