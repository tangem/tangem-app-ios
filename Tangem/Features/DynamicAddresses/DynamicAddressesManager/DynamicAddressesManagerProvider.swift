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
    let derivationModeUpdater: DerivationModeUpdater
    let userTokensManager: UserTokensManager

    func makeDynamicAddressesManager(
        tokenItem: TokenItem,
        walletManager: any WalletManager
    ) -> DynamicAddressesManager? {
        guard tokenItem.blockchain.isDynamicAddressesSupported else {
            return nil
        }

        guard let xpubAddressesWalletManagerProvider = walletManager as? XPUBAddressesWalletManagerProvider else {
            assertionFailure("WalletManager does not conform to XPUBAddressesWalletManagerProvider for blockchain: \(tokenItem.blockchain)")
            return nil
        }

        let generator = CommonXPUBKeyGenerator(
            keysRepository: keysRepository,
            keysDerivingInteractor: keysDerivingInteractor,
            tokenItem: tokenItem
        )

        return CommonDynamicAddressesManager(
            tokenItem: tokenItem,
            xpubAddressesWalletManagerProvider: xpubAddressesWalletManagerProvider,
            xpubKeyGenerator: generator,
            derivationModeUpdater: derivationModeUpdater,
            userTokensManager: userTokensManager
        )
    }
}
