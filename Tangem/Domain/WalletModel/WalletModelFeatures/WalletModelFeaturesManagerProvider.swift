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
    let derivationManager: DerivationManager?

    func makeWalletModelFeaturesManager(
        tokenItem: TokenItem,
        walletManager: any WalletManager
    ) -> any WalletModelFeaturesManager {
        let nftFeatureManager = CommonWalletModelNFTFeatureManager(
            userWalletId: userWalletId,
            userWalletConfig: userWalletConfig,
            tokenItem: tokenItem
        )

        let dynamicAddressesManager = makeDynamicAddressesManager(
            tokenItem: tokenItem,
            walletManager: walletManager
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

// MARK: - Private

private extension WalletModelFeaturesManagerProvider {
    func makeDynamicAddressesManager(tokenItem: TokenItem, walletManager: any WalletManager) -> DynamicAddressesManager? {
        guard tokenItem.blockchain.isDynamicAddressesSupported else {
            return nil
        }

        guard let derivationManager else {
            return nil
        }

        return CommonDynamicAddressesManager(
            userWalletConfig: userWalletConfig,
            tokenItem: tokenItem,
            keysProvider: keysProvider,
            walletUpdater: walletManager,
            derivationManager: derivationManager
        )
    }
}
