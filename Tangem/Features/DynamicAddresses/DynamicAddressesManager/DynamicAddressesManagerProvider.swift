//
//  DynamicAddressesManagerProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemSdk

struct DynamicAddressesManagerProvider {
    let keysRepository: KeysRepository
    let keysDerivingInteractor: KeysDeriving
    let derivationLevelUpdater: DerivationLevelUpdater

    func makeDynamicAddressesManager(
        tokenItem: TokenItem,
        walletManager: any WalletManager
    ) -> DynamicAddressesManager? {
        guard tokenItem.blockchain.isDynamicAddressesSupported else {
            return nil
        }

        let generator = CommonXPUBKeyGenerator(
            keysRepository: keysRepository,
            keysDerivingInteractor: keysDerivingInteractor,
            tokenItem: tokenItem
        )

        let dynamicAddressesWalletUpdater = DynamicAddressesWalletUpdater(
            walletProvider: walletManager,
            walletUpdater: walletManager
        )

        return CommonDynamicAddressesManager(
            tokenItem: tokenItem,
            dynamicAddressesWalletUpdater: dynamicAddressesWalletUpdater,
            xpubKeyGenerator: generator,
            derivationLevelUpdater: derivationLevelUpdater
        )
    }
}
