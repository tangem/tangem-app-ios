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

    func makeWalletModelFeaturesManager(
        tokenItem: TokenItem,
        walletManager: any WalletManager
    ) -> any WalletModelFeaturesManager {
        let nftFeatureManager = CommonWalletModelNFTFeatureManager(
            userWalletId: userWalletId,
            userWalletConfig: userWalletConfig,
            tokenItem: tokenItem
        )

        return CommonWalletModelFeaturesManager(nftFeatureManager: nftFeatureManager)
    }
}
