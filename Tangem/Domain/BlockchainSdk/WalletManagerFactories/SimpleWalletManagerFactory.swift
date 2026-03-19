//
//  SimpleWalletManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SimpleWalletManagerFactory: AnyWalletManagerFactory {
    func makeWalletManager(blockchainNetwork: BlockchainNetwork, tokens: [Token], keys: [KeyInfo], apiList: APIList) throws -> WalletManager {
        let publicKey = try SimpleWalletPublicKeyFactory().makePublicKey(blockchainNetwork: blockchainNetwork, keys: keys)

        let factory = WalletManagerFactoryProvider(apiList: apiList).factory
        let walletManager = try factory.makeWalletManager(blockchain: blockchainNetwork.blockchain, publicKey: publicKey)

        walletManager.addTokens(tokens)
        return walletManager
    }
}
