//
//  CryptoAccountDependencies.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CryptoAccountDependencies {
    let userTokensManager: UserTokensManager
    let walletModelsManager: WalletModelsManager
    let walletModelsFactoryInput: AccountsAwareWalletModelsFactoryInput
    let derivationManager: DerivationManager?

    func makeBalanceProvidingDependencies() -> (
        balanceProvider: AccountBalanceProvider,
        ratesProvider: AccountRateProvider
    ) {
        let totalBalanceProvider = WalletModelsTotalBalanceProvider(
            walletModelsManager: walletModelsManager,
            analyticsLogger: AccountTotalBalanceProviderAnalyticsLogger(),
            derivationManager: derivationManager
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
