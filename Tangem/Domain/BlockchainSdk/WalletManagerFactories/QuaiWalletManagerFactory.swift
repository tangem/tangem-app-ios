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

        let zoneDerivedKey = try executeDerivedKey(derivedKey)
        let zoneDerivationPath = derivationPath.extendedPath(with: .nonHardened(31))

        let derivationKey = Wallet.PublicKey.HDKey(path: zoneDerivationPath, extendedPublicKey: zoneDerivedKey)
        let publicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: .plain(derivationKey))

        let factory = WalletManagerFactoryProvider(apiList: apiList).factory
        let walletManager = try factory.makeWalletManager(blockchain: blockchain, publicKey: publicKey)

        walletManager.addTokens(token.tokens)
        return walletManager
    }

    // MARK: - Private Implementation

    private func deriveByZone(extendendPublicKey: ExtendedPublicKey) throws -> (ExtendedPublicKey, DerivationNode) {
        let quaiAddressUtils = QuaiAddressUtils()
        return try quaiAddressUtils.derive(extendendPublicKey: extendendPublicKey, with: .default)
    }

    private func executeDerivedKey(_ derivedKey: ExtendedPublicKey) throws -> (ExtendedPublicKey, DerivationNode) {
        var storedKey: ExtendedPublicKey?
        var error: Error?
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                let storageKeySuffix = derivedKey.publicKey.getSha256().hexString
                let cacheDerivedKey: ExtendedPublicKey? = await dataStorage.get(key: storageKeySuffix)
                
                derivedKey.derivePublicKey(node: .nonHardened(<#T##UInt32#>))

//                if let cacheDerivedKey {
//                    storedKey = cacheDerivedKey
//                } else {
                let savedDerivedKey = try deriveByZone(extendendPublicKey: derivedKey)
                await dataStorage.store(key: storageKeySuffix, value: savedDerivedKey.0)
                storedKey = savedDerivedKey.0
//                }
            } catch let e {
                error = e
            }
            semaphore.signal()
        }

        semaphore.wait()

        if let error {
            throw error
        }

        if let storedKey {
            return storedKey
        } else {
            throw BlockchainSdkError.failedToConvertPublicKey
        }
    }
}
