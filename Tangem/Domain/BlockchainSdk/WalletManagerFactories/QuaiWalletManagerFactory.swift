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

    func makeWalletManager(for token: StorageEntry, keys: [KeyInfo], apiList: APIList) throws -> WalletManager {
        let seedKeys: [EllipticCurve: Data] = keys.reduce(into: [:]) { partialResult, cardWallet in
            partialResult[cardWallet.curve] = cardWallet.publicKey
        }

        let derivedKeys: [EllipticCurve: [DerivationPath: ExtendedPublicKey]] = keys.reduce(into: [:]) { partialResult, cardWallet in
            partialResult[cardWallet.curve] = cardWallet.derivedKeys
        }

        let blockchain = token.blockchainNetwork.blockchain
        let curve = blockchain.curve

        guard let derivationPath = token.blockchainNetwork.derivationPath else {
            throw AnyWalletManagerFactoryError.entryHasNotDerivationPath
        }

        guard let seedKey = seedKeys[curve], let derivedWalletKeys = derivedKeys[curve] else {
            throw AnyWalletManagerFactoryError.walletWithBlockchainCurveNotFound
        }

        guard let derivedKey = derivedWalletKeys[derivationPath] else {
            throw AnyWalletManagerFactoryError.noDerivation
        }

        let zoneDerivedKey = try zoneDerived(key: derivedKey, with: derivationPath)
        let publicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: .plain(zoneDerivedKey))

        let factory = WalletManagerFactoryProvider(apiList: apiList).factory
        let walletManager = try factory.makeWalletManager(blockchain: blockchain, publicKey: publicKey)

        walletManager.addTokens(token.tokens)
        return walletManager
    }

    // MARK: - Private Implementation

    private func zoneDerived(key: ExtendedPublicKey, with derivationPath: DerivationPath) throws -> Wallet.PublicKey.HDKey {
        var storedKey: Wallet.PublicKey.HDKey

        let storageKeySuffix = key.publicKey.getSha256().hexString
        let cacheDerivedKey: Wallet.PublicKey.HDKey? = dataStorage.get(key: storageKeySuffix)

        if let cacheDerivedKey {
            storedKey = cacheDerivedKey
        } else {
            let zoneDerivedResult = try quaiDerivationUtils.derive(extendendPublicKey: key, with: .default)
            let zoneDerivationPath = derivationPath.extendedPath(with: zoneDerivedResult.1)

            let derivedHDKey = Wallet.PublicKey.HDKey(path: zoneDerivationPath, extendedPublicKey: zoneDerivedResult.0)

            dataStorage.store(key: storageKeySuffix, value: derivedHDKey)
            storedKey = derivedHDKey
        }

        return storedKey
    }
}
