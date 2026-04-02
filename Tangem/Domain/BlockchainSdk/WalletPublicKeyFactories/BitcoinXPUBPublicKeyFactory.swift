//
//  BitcoinXPUBPublicKeyFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct BitcoinXPUBPublicKeyFactory: AnyWalletPublicKeyFactory {
    func makePublicKey(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet.PublicKey {
        let seedKeys: [EllipticCurve: Data] = keys.reduce(into: [:]) { partialResult, cardWallet in
            partialResult[cardWallet.curve] = cardWallet.publicKey
        }

        let derivedKeys: [EllipticCurve: [DerivationPath: ExtendedPublicKey]] = keys.reduce(into: [:]) { partialResult, cardWallet in
            partialResult[cardWallet.curve] = cardWallet.derivedKeys
        }

        let blockchain = blockchainNetwork.blockchain
        let curve = blockchain.curve

        guard let derivationPath = blockchainNetwork.derivationPath else {
            throw AnyWalletManagerFactoryError.entryHasNotDerivationPath
        }

        guard let seedKey = seedKeys[curve], let derivedWalletKeys = derivedKeys[curve] else {
            throw AnyWalletManagerFactoryError.walletWithBlockchainCurveNotFound
        }

        let xpubPaths = try XPUBUtils().xpubDerivationPaths(for: derivationPath)

        guard let derivedKey = derivedWalletKeys[derivationPath],
              let childExtKey = derivedWalletKeys[xpubPaths.child],
              let parentExtKey = derivedWalletKeys[xpubPaths.parent] else {
            throw AnyWalletManagerFactoryError.noDerivation
        }

        let derivationKey = Wallet.PublicKey.HDKey(path: derivationPath, extendedPublicKey: derivedKey)
        let xpubKey = Wallet.PublicKey.XPUBKey(
            child: .init(path: xpubPaths.child, extendedPublicKey: childExtKey),
            parent: .init(path: xpubPaths.parent, extendedPublicKey: parentExtKey)
        )

        return Wallet.PublicKey(seedKey: seedKey, derivationType: .xpub(plain: derivationKey, xpub: xpubKey))
    }
}
