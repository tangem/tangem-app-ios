//
//  CardanoWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct CardanoWalletFactory: AnyWalletFactory {
    func makeWallet(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet {
        let publicKey = try makePublicKey(blockchainNetwork: blockchainNetwork, keys: keys)

        return try WalletFactory(blockchain: blockchainNetwork.blockchain).makeWallet(publicKey: publicKey)
    }

    private func makePublicKey(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet.PublicKey {
        let seedKeys: [EllipticCurve: Data] = keys.reduce(into: [:]) { partialResult, cardWallet in
            partialResult[cardWallet.curve] = cardWallet.publicKey
        }

        let derivedKeys: [EllipticCurve: [DerivationPath: ExtendedPublicKey]] = keys.reduce(into: [:]) { partialResult, cardWallet in
            partialResult[cardWallet.curve] = cardWallet.derivedKeys
        }

        let blockchain = blockchainNetwork.blockchain
        let curve = blockchain.curve

        guard let derivationPath = blockchainNetwork.derivationPath else {
            throw AnyWalletFactoryError.entryHasNotDerivationPath
        }

        guard let seedKey = seedKeys[curve], let derivedWalletKeys = derivedKeys[curve] else {
            throw AnyWalletFactoryError.walletWithBlockchainCurveNotFound
        }

        let extendedDerivationPath = try CardanoUtil().extendedDerivationPath(for: derivationPath)

        guard let derivedKey = derivedWalletKeys[derivationPath],
              let secondDerivedKey = derivedWalletKeys[extendedDerivationPath] else {
            throw AnyWalletFactoryError.noDerivation
        }

        let derivationKey = Wallet.PublicKey.HDKey(path: derivationPath, extendedPublicKey: derivedKey)
        let secondDerivationKey = Wallet.PublicKey.HDKey(path: extendedDerivationPath, extendedPublicKey: secondDerivedKey)

        return Wallet.PublicKey(
            seedKey: seedKey,
            derivationType: .double(first: derivationKey, second: secondDerivationKey)
        )
    }
}
