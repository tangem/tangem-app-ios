//
//  WalletModelFeaturesManagerFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemFoundation

struct WalletModelFeaturesManagerFactory {
    let userWalletId: UserWalletId
    let userWalletConfig: UserWalletConfig
    let dynamicAddressesManagerProvider: DynamicAddressesManagerProvider
    let transactionHistoryProviderRegistry: TransactionHistoryProviderRegistry

    func makeWalletModelFeaturesManager(
        tokenItem: TokenItem,
        walletManager: any WalletManager
    ) -> any WalletModelFeaturesManager {
        let nftFeatureManager = CommonWalletModelNFTFeatureManager(
            userWalletId: userWalletId,
            userWalletConfig: userWalletConfig,
            tokenItem: tokenItem
        )

        let dynamicAddressesFeatureManager = CommonWalletModelDynamicAddressesFeatureManager(
            dynamicAddressesManager: dynamicAddressesManagerProvider.makeDynamicAddressesManager(
                tokenItem: tokenItem,
                walletManager: walletManager
            )
        )

        let transactionHistoryFeatureManager = CommonWalletModelTransactionHistoryFeatureManager(
            key: TransactionHistoryProviderKey(address: walletManager.wallet.address), // [REDACTED_TODO_COMMENT]
            tokenItem: tokenItem,
            registry: transactionHistoryProviderRegistry
        )

        return CommonWalletModelFeaturesManager(
            nftFeatureManager: nftFeatureManager,
            dynamicAddressesFeatureManager: dynamicAddressesFeatureManager,
            transactionHistoryFeatureManager: transactionHistoryFeatureManager
        )
    }
}
