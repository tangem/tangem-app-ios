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
    let transactionHistorySyncRegistry: any TransactionHistorySyncRegistry

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
            key: TransactionHistorySyncKey(
                userWalletId: userWalletId,
                address: walletManager.wallet.address
            ),
            tokenItem: tokenItem,
            registry: transactionHistorySyncRegistry
        )

        return CommonWalletModelFeaturesManager(
            nftFeatureManager: nftFeatureManager,
            dynamicAddressesFeatureManager: dynamicAddressesFeatureManager,
            transactionHistoryFeatureManager: transactionHistoryFeatureManager
        )
    }
}
