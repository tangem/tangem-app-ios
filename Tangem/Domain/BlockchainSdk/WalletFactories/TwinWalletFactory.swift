//
//  TwinWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import BlockchainSdk

/// The Tangem Twin cards keep their funds behind a multisig script of the two cards' keys, on Bitcoin alone.
struct TwinWalletFactory: AnyWalletFactory {
    private let pairPublicKey: Data?

    init(pairPublicKey: Data?) {
        self.pairPublicKey = pairPublicKey
    }

    /// - Parameter blockchainNetwork: Unused: a twin wallet lives on Bitcoin whatever network the entry names.
    func makeWallet(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet {
        guard let walletPublicKey = keys.first?.publicKey, let pairPublicKey else {
            throw AnyWalletFactoryError.twinWalletPublicKeyNotFound
        }

        let blockchain: Blockchain = .bitcoin(testnet: AppEnvironment.current.isTestnet)
        let publicKey = Wallet.PublicKey(seedKey: walletPublicKey, derivationType: .none)

        return try WalletFactory(blockchain: blockchain).makeWallet(publicKey: publicKey, pairPublicKey: pairPublicKey)
    }
}
