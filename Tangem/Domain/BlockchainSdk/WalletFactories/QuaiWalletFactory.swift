//
//  QuaiWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct QuaiWalletFactory: AnyWalletFactory {
    // MARK: - Properties

    private let dataStorage: BlockchainDataStorage
    private let quaiDerivationUtils = QuaiDerivationUtils()

    // MARK: - Init

    init(dataStorage: BlockchainDataStorage) {
        self.dataStorage = dataStorage
    }

    // MARK: - AnyWalletFactory

    func makeWallet(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet {
        let publicKey = try makePublicKey(blockchainNetwork: blockchainNetwork, keys: keys)

        return try WalletFactory(blockchain: blockchainNetwork.blockchain).makeWallet(publicKey: publicKey)
    }

    // MARK: - Private Implementation

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

        guard let derivedKey = derivedWalletKeys[derivationPath] else {
            throw AnyWalletFactoryError.noDerivation
        }

        let zoneDerivedKey = try deriveZone(extendedPublicKey: derivedKey, with: derivationPath)
        return Wallet.PublicKey(seedKey: seedKey, derivationType: .plain(zoneDerivedKey))
    }

    private func deriveZone(extendedPublicKey: ExtendedPublicKey, with derivationPath: DerivationPath) throws -> Wallet.PublicKey.HDKey {
        let storageKeyIndexSuffix = "\(Constants.quaiDerivationNodeStorageKey)_\(extendedPublicKey.publicKey.getSHA256().hexString)"

        if let cacheDerivedNodeIndex: UInt32 = dataStorage.get(key: storageKeyIndexSuffix) {
            return try Wallet.PublicKey.HDKey(
                path: derivationPath.extendedPath(with: .nonHardened(cacheDerivedNodeIndex)),
                extendedPublicKey: extendedPublicKey.derivePublicKey(node: .nonHardened(cacheDerivedNodeIndex))
            )
        }

        let zoneDerivedResult = try quaiDerivationUtils.derive(extendedPublicKey: extendedPublicKey, with: .default)
        dataStorage.store(key: storageKeyIndexSuffix, value: zoneDerivedResult.node.index)

        return Wallet.PublicKey.HDKey(
            path: derivationPath.extendedPath(with: zoneDerivedResult.node),
            extendedPublicKey: zoneDerivedResult.key
        )
    }
}

// MARK: - Constants

extension QuaiWalletFactory {
    enum Constants {
        static let quaiDerivationNodeStorageKey = "quaiDerivationNodeStorageKey"
    }
}
