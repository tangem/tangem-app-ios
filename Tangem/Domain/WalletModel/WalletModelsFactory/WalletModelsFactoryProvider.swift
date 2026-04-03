//
//  WalletModelsFactoryProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct WalletModelsFactoryProvider {
    let userWalletId: UserWalletId
    let userWalletConfig: UserWalletConfig
    let keysProvider: KeysProvider
    let derivationManager: DerivationManager?

    func makeWalletModelsFactory() -> any WalletModelsFactory {
        let featuresManagerProvider = WalletModelFeaturesManagerProvider(
            userWalletId: userWalletId,
            userWalletConfig: userWalletConfig,
            keysProvider: keysProvider,
            derivationManager: derivationManager
        )

        let factory = CommonWalletModelsFactory(
            config: userWalletConfig,
            userWalletId: userWalletId,
            walletModelFeaturesManagerProvider: featuresManagerProvider
        )

        if userWalletConfig.isDemo {
            return DemoWalletModelsFactory(innerFactory: factory)
        }

        return factory
    }
}
