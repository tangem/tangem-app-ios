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
    let transactionHistoryProviderResolver: TransactionHistoryProviderResolver

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
            providerResolver: transactionHistoryProviderResolver,
            tokenItem: tokenItem
        )

        return CommonWalletModelFeaturesManager(
            nftFeatureManager: nftFeatureManager,
            dynamicAddressesFeatureManager: dynamicAddressesFeatureManager,
            transactionHistoryFeatureManager: transactionHistoryFeatureManager
        )
    }
}
