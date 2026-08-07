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
        let nftFeatureManager = WalletModelNFTFeatureManager(
            userWalletId: userWalletId,
            userWalletConfig: userWalletConfig,
            tokenItem: tokenItem
        )

        let dynamicAddressesFeatureManager = WalletModelDynamicAddressesFeatureManager(
            dynamicAddressesManager: dynamicAddressesManagerProvider.makeDynamicAddressesManager(
                tokenItem: tokenItem,
                walletManager: walletManager
            )
        )

        let transactionHistoryFeatureManager = WalletModelTransactionHistoryFeatureManager(
            // [REDACTED_TODO_COMMENT]
            key: TransactionHistoryProviderKey(address: walletManager.wallet.address, tokenItem: tokenItem),
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
