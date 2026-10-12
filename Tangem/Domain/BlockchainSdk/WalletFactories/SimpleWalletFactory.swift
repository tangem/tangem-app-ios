//
//  SimpleWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SimpleWalletFactory: AnyWalletFactory {
    func makeWallet(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet {
        let publicKey = try makePublicKey(blockchainNetwork: blockchainNetwork, keys: keys)

        return try WalletFactory(blockchain: blockchainNetwork.blockchain).makeWallet(publicKey: publicKey)
    }

    private func makePublicKey(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet.PublicKey {
        let blockchain = blockchainNetwork.blockchain

        guard let walletPublicKey = keys.first(where: { $0.curve == blockchain.curve })?.publicKey else {
            throw AnyWalletFactoryError.walletWithBlockchainCurveNotFound
        }

        return Wallet.PublicKey(seedKey: walletPublicKey, derivationType: .none)
    }
}
