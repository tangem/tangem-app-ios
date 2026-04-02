//
//  DynamicAddressesManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol DynamicAddressesManager {
    func disableDynamicAddresses() async throws
    func enableDynamicAddresses() async throws
}

class CommonDynamicAddressesManager {
    let userWalletConfig: UserWalletConfig
    let tokenItem: TokenItem
    let keysProvider: KeysProvider
    let walletUpdater: WalletUpdater
    let derivationManager: DerivationManager

    init(
        userWalletConfig: UserWalletConfig,
        tokenItem: TokenItem,
        keysProvider: KeysProvider,
        walletUpdater: WalletUpdater,
        derivationManager: DerivationManager
    ) {
        self.userWalletConfig = userWalletConfig
        self.tokenItem = tokenItem
        self.keysProvider = keysProvider
        self.walletUpdater = walletUpdater
        self.derivationManager = derivationManager
    }
}

// MARK: - DynamicAddressesManager

extension CommonDynamicAddressesManager: DynamicAddressesManager {
    func disableDynamicAddresses() async throws {
        // [REDACTED_TODO_COMMENT]
        fatalError("Not implemented yet")
    }

    func enableDynamicAddresses() async throws {
        let xpubBlockchain = try tokenItem.blockchain.updated(xpub: true)
        let blockchainNetwork = BlockchainNetwork(xpubBlockchain, derivationPath: tokenItem.blockchainNetwork.derivationPath)

        if derivationManager.shouldDeriveKeys(networksToRemove: [], networksToAdd: [blockchainNetwork]) {
            try await derivationManager.deriveKeys()
        }

        let keys = keysProvider.keys
        let publicKey = try BitcoinXPUBPublicKeyFactory().makePublicKey(blockchainNetwork: blockchainNetwork, keys: keys)
        let wallet = try WalletFactory(blockchain: xpubBlockchain).makeWallet(publicKey: publicKey)

        // [REDACTED_TODO_COMMENT]

        try walletUpdater.update(wallet: wallet)
    }
}
