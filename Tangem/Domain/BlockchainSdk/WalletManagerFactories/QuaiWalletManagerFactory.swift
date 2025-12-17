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
    private let evmAddressService = EVMAddressService()
    private let quaiDerivationUtils = QuaiDerivationUtils()

    // MARK: - Init

    init(dataStorage: BlockchainDataStorage) {
        self.dataStorage = dataStorage
    }

    // MARK: - AnyWalletManagerFactory

    func makeWalletManager(blockchainNetwork: BlockchainNetwork, tokens: [Token], keys: [KeyInfo], apiList: APIList) throws -> WalletManager {
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
        let publicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: .plain(zoneDerivedKey))

        let factory = WalletManagerFactoryProvider(apiList: apiList).factory
        let walletManager = try factory.makeWalletManager(blockchain: blockchain, publicKey: publicKey)

        walletManager.addTokens(tokens)
        return walletManager
    }

    // MARK: - Private Implementation

    private func deriveZone(extendedPublicKey: ExtendedPublicKey, with derivationPath: DerivationPath) throws -> Wallet.PublicKey.HDKey {
        var zoneExtendedPublicKey: ExtendedPublicKey
        var zoneDerivationPath: DerivationPath

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

        let resultHDKey = Wallet.PublicKey.HDKey(path: zoneDerivationPath, extendedPublicKey: zoneExtendedPublicKey)

        return resultHDKey
    }
}

// MARK: - Constants

extension QuaiWalletManagerFactory {
    enum Constants {
        static let quaiDerivationNodeStorageKey = "quaiDerivationNodeStorageKey"
    }
}
