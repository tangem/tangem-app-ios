//
//  WalletModelFeaturesManagerProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemFoundation

struct WalletModelFeaturesManagerProvider {
    let userWalletId: UserWalletId
    let userWalletConfig: UserWalletConfig
    let keysProvider: KeysProvider

    func makeWalletModelFeaturesManager(
        tokenItem: TokenItem,
        walletManager: any WalletManager
    ) -> any WalletModelFeaturesManager {
        let nftFeatureManager = CommonWalletModelNFTFeatureManager(
            userWalletId: userWalletId,
            userWalletConfig: userWalletConfig,
            tokenItem: tokenItem
        )

        let dynamicAddressesManager = CommmonDynamicAddressesManager(
            userWalletConfig: userWalletConfig,
            tokenItem: tokenItem,
            keysProvider: keysProvider,
            walletUpdater: walletManager
        )

        let dynamicAddressesFeatureManager = CommonWalletModelDynamicAddressesFeatureManager(
            dynamicAddressesManager: dynamicAddressesManager
        )

        let featureManager = CommonWalletModelFeaturesManager(
            nftFeatureManager: nftFeatureManager,
            dynamicAddressesFeatureManager: dynamicAddressesFeatureManager
        )

        return featureManager
    }
}
