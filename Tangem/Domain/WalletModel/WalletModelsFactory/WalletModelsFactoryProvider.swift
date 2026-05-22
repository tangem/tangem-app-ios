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
    let transactionHistoryProviderRegistry: TransactionHistoryProviderRegistry

    func makeWalletModelsFactory(
        blockchainSettingsUpdater: BlockchainSettingsUpdater,
        userTokensManager: UserTokensManager
    ) -> any WalletModelsFactory {
        let dynamicAddressesManagerProvider = DynamicAddressesManagerProvider(
            keysRepository: keysRepository,
            keysDerivingInteractor: keysDerivingInteractor,
            blockchainSettingsUpdater: blockchainSettingsUpdater,
            userTokensManager: userTokensManager
        )

        let featuresManagerFactory = WalletModelFeaturesManagerFactory(
            userWalletId: userWalletId,
            userWalletConfig: userWalletConfig,
            dynamicAddressesManagerProvider: dynamicAddressesManagerProvider,
            transactionHistoryProviderRegistry: transactionHistoryProviderRegistry
        )

        let transactionHistoryServiceProvider = TransactionHistoryServiceProvider()

        let factory = CommonWalletModelsFactory(
            config: userWalletConfig,
            userWalletId: userWalletId,
            walletModelFeaturesManagerFactory: featuresManagerFactory,
            transactionHistoryServiceProvider: transactionHistoryServiceProvider
        )

        if userWalletConfig.isDemo {
            return DemoWalletModelsFactory(innerFactory: factory)
        }

        return factory
    }
}
