//
//  BitcoinXPUBWalletManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct BitcoinXPUBWalletManagerFactory: AnyWalletManagerFactory {
    func makeWalletManager(blockchainNetwork: BlockchainNetwork, tokens: [Token], keys: [KeyInfo], apiList: APIList) throws -> WalletManager {
        let publicKey = try BitcoinXPUBPublicKeyFactory().makePublicKey(blockchainNetwork: blockchainNetwork, keys: keys)

        let factory = WalletManagerFactoryProvider(apiList: apiList).factory
        let walletManager = try factory.makeWalletManager(blockchain: blockchainNetwork.blockchain, publicKey: publicKey)

        walletManager.addTokens(tokens)
        return walletManager
    }
}
