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
        userTokensManager: UserTokensManager,
        isSafe: Bool = false,
        isEarnSupported: Bool = true
    ) -> any WalletModelsFactory {
        let dynamicAddressesManagerProvider = DynamicAddressesManagerProvider(
            keysRepository: keysRepository,
            keysDerivingInteractorFactory: keysDerivingInteractorFactory,
            blockchainSettingsUpdater: blockchainSettingsUpdater,
            userTokensManager: userTokensManager
        )

        return makeWalletModelsFactory(
            dynamicAddressesManagerProvider: dynamicAddressesManagerProvider,
            isSafe: isSafe,
            isEarnSupported: isEarnSupported
        )
    }

    func makeStandaloneWalletModelsFactory() -> any WalletModelsFactory {
        makeWalletModelsFactory(dynamicAddressesManagerProvider: nil, isSafe: false, isEarnSupported: false)
    }

    private func makeWalletModelsFactory(
        dynamicAddressesManagerProvider: DynamicAddressesManagerProvider?,
        isSafe: Bool,
        isEarnSupported: Bool
    ) -> any WalletModelsFactory {
        let featuresManagerFactory = WalletModelFeaturesManagerFactory(
            userWalletId: userWalletId,
            userWalletConfig: userWalletConfig,
            dynamicAddressesManagerProvider: dynamicAddressesManagerProvider,
            transactionHistoryProviderResolver: transactionHistoryProviderResolver,
            isSafe: isSafe
        )

        let transactionHistoryServiceProvider = TransactionHistoryServiceProvider(isSafe: isSafe)

        let factory = CommonWalletModelsFactory(
            config: userWalletConfig,
            userWalletId: userWalletId,
            walletModelFeaturesManagerFactory: featuresManagerFactory,
            transactionHistoryServiceProvider: transactionHistoryServiceProvider,
            transactionHistoryUpdater: transactionHistoryUpdater,
            isEarnSupported: isEarnSupported
        )

        if userWalletConfig.isDemo {
            return DemoWalletModelsFactory(innerFactory: factory)
        }

        return factory
    }
}
