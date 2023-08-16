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
    func makeWalletManager(
        tokens: [BlockchainSdk.Token],
        blockchainNetwork: BlockchainNetwork,
        keys: [CardDTO.Wallet]
    ) throws -> WalletManager {
        let blockchain = blockchainNetwork.blockchain

        guard let walletPublicKey = keys.first(where: { $0.curve == blockchain.curve })?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider().factory
        let publicKey = Wallet.PublicKey(seedKey: walletPublicKey, derivation: .none)
        let walletManager = try factory.makeWalletManager(blockchain: blockchain, publicKey: publicKey)

        walletManager.addTokens(tokens)
        return walletManager
    }
}
