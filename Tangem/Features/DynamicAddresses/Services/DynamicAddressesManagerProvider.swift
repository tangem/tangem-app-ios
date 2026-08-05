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
    let keysDerivingInteractorFactory: KeysDerivingInteractorFactory
    let blockchainSettingsUpdater: BlockchainSettingsUpdater
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

        guard let xpubAddressesBalancesChecker = walletManager as? XPUBAddressesBalancesChecker else {
            assertionFailure("WalletManager does not conform to XPUBAddressesBalancesChecker for blockchain: \(tokenItem.blockchain)")
            return nil
        }

        let generator = CommonXPUBKeyGenerator(
            keysRepository: keysRepository,
            keysDerivingInteractorFactory: keysDerivingInteractorFactory,
            tokenItem: tokenItem
        )

        return CommonDynamicAddressesManager(
            tokenItem: tokenItem,
            xpubAddressesWalletManagerProvider: xpubAddressesWalletManagerProvider,
            xpubAddressesBalancesChecker: xpubAddressesBalancesChecker,
            xpubKeyGenerator: generator,
            blockchainSettingsUpdater: blockchainSettingsUpdater,
            userTokensManager: userTokensManager
        )
    }
}
