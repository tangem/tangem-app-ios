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

    var accountBalanceProvider: AccountBalanceProvider {
        let totalBalanceProvider = WalletModelsTotalBalanceProvider(
            walletModelsManager: walletModelsManager,
            analyticsLogger: AccountTotalBalanceProviderAnalyticsLogger(),
            derivationManager: userTokensManager.derivationManager
        )

        return CommonAccountBalanceProvider(totalBalanceProvider: totalBalanceProvider)
    }
}
