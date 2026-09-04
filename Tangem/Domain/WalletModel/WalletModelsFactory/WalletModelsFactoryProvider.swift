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
    let keysDerivingInteractorFactory: KeysDerivingInteractorFactory
    let transactionHistoryProviderResolver: TransactionHistoryProviderResolver
    let transactionHistoryUpdater: TransactionHistoryUpdater

    func makeWalletModelsFactory(
        blockchainSettingsUpdater: BlockchainSettingsUpdater,
        userTokensManager: UserTokensManager
    ) -> any WalletModelsFactory {
        let dynamicAddressesManagerProvider = DynamicAddressesManagerProvider(
            keysRepository: keysRepository,
            keysDerivingInteractorFactory: keysDerivingInteractorFactory,
            blockchainSettingsUpdater: blockchainSettingsUpdater,
            userTokensManager: userTokensManager
        )

        let featuresManagerFactory = WalletModelFeaturesManagerFactory(
            userWalletId: userWalletId,
            userWalletConfig: userWalletConfig,
            dynamicAddressesManagerProvider: dynamicAddressesManagerProvider,
            transactionHistoryProviderResolver: transactionHistoryProviderResolver
        )

        let transactionHistoryServiceProvider = TransactionHistoryServiceProvider()

        let factory = CommonWalletModelsFactory(
            config: userWalletConfig,
            userWalletId: userWalletId,
            walletModelFeaturesManagerFactory: featuresManagerFactory,
            transactionHistoryServiceProvider: transactionHistoryServiceProvider,
            transactionHistoryUpdater: transactionHistoryUpdater
        )

        if userWalletConfig.isDemo {
            return DemoWalletModelsFactory(innerFactory: factory)
        }

        return factory
    }
}
