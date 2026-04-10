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
    let keysRepository: KeysRepository
    let keysDerivingInteractor: KeysDeriving

    func makeWalletModelsFactory(derivationLevelUpdater: DerivationLevelUpdater) -> any WalletModelsFactory {
        let dynamicAddressesManagerProvider = DynamicAddressesManagerProvider(
            keysRepository: keysRepository,
            keysDerivingInteractor: keysDerivingInteractor,
            derivationLevelUpdater: derivationLevelUpdater
        )

        let featuresManagerProvider = WalletModelFeaturesManagerProvider(
            userWalletId: userWalletId,
            userWalletConfig: userWalletConfig,
            dynamicAddressesManagerProvider: dynamicAddressesManagerProvider
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
