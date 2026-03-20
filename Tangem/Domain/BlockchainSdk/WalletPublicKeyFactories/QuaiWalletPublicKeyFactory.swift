//
//  QuaiWalletPublicKeyFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct QuaiWalletPublicKeyFactory: AnyWalletPublicKeyFactory {
    // MARK: - Properties

    private let dataStorage: BlockchainDataStorage?
    private let quaiDerivationUtils = QuaiDerivationUtils()

    // MARK: - Init

    init(dataStorage: BlockchainDataStorage? = nil) {
        self.dataStorage = dataStorage
    }

    // MARK: - AnyWalletPublicKeyFactory

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

        guard let derivedKey = derivedWalletKeys[derivationPath] else {
            throw AnyWalletManagerFactoryError.noDerivation
        }

        let zoneDerivedKey = try deriveZone(extendedPublicKey: derivedKey, with: derivationPath)
        return Wallet.PublicKey(seedKey: seedKey, derivationType: .plain(zoneDerivedKey))
    }

    // MARK: - Private Implementation

    private func deriveZone(extendedPublicKey: ExtendedPublicKey, with derivationPath: DerivationPath) throws -> Wallet.PublicKey.HDKey {
        var zoneExtendedPublicKey: ExtendedPublicKey
        var zoneDerivationPath: DerivationPath

        if let dataStorage {
            let storageKeyIndexSuffix = "\(Constants.quaiDerivationNodeStorageKey)_\(extendedPublicKey.publicKey.getSHA256().hexString)"

            if let cacheDerivedNodeIndex: UInt32 = dataStorage.get(key: storageKeyIndexSuffix) {
                let derivedNode: DerivationNode = .nonHardened(UInt32(cacheDerivedNodeIndex))

                zoneExtendedPublicKey = try extendedPublicKey.derivePublicKey(node: derivedNode)
                zoneDerivationPath = derivationPath.extendedPath(with: .nonHardened(cacheDerivedNodeIndex))
            } else {
                let zoneDerivedResult = try quaiDerivationUtils.derive(extendedPublicKey: extendedPublicKey, with: .default)

                dataStorage.store(key: storageKeyIndexSuffix, value: zoneDerivedResult.node.index)

                zoneExtendedPublicKey = zoneDerivedResult.key
                zoneDerivationPath = derivationPath.extendedPath(with: zoneDerivedResult.node)
            }
        } else {
            let zoneDerivedResult = try quaiDerivationUtils.derive(extendedPublicKey: extendedPublicKey, with: .default)

            zoneExtendedPublicKey = zoneDerivedResult.key
            zoneDerivationPath = derivationPath.extendedPath(with: zoneDerivedResult.node)
        }

        return Wallet.PublicKey.HDKey(path: zoneDerivationPath, extendedPublicKey: zoneExtendedPublicKey)
    }
}

// MARK: - Constants

extension QuaiWalletPublicKeyFactory {
    enum Constants {
        static let quaiDerivationNodeStorageKey = "quaiDerivationNodeStorageKey"
    }
}
