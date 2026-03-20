//
//  QuaiWalletManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct QuaiWalletManagerFactory: AnyWalletManagerFactory {
    // MARK: - Properties

    private let dataStorage: BlockchainDataStorage

    // MARK: - Init

    init(dataStorage: BlockchainDataStorage) {
        self.dataStorage = dataStorage
    }

    // MARK: - AnyWalletManagerFactory

    func makeWalletManager(blockchainNetwork: BlockchainNetwork, tokens: [Token], keys: [KeyInfo], apiList: APIList) throws -> WalletManager {
        let publicKey = try QuaiWalletPublicKeyFactory(dataStorage: dataStorage).makePublicKey(
            blockchainNetwork: blockchainNetwork,
            keys: keys
        )

        let factory = WalletManagerFactoryProvider(apiList: apiList).factory
        let walletManager = try factory.makeWalletManager(blockchain: blockchainNetwork.blockchain, publicKey: publicKey)

        walletManager.addTokens(tokens)
        return walletManager
    }
}
