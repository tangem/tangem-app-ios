//
//  WalletModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class WalletModelFactory {
    func makeSingleWallet(walletPublicKey: Data,
                          blockchain: Blockchain,
                          token: BlockchainSdk.Token?,
                          derivationStyle: DerivationStyle) throws -> WalletModel {
        let factory = WalletManagerFactoryProvider().factory
        let walletManager = try factory.makeWalletManager(blockchain: blockchain,
                                                          walletPublicKey: walletPublicKey)
        if let token = token {
            walletManager.addTokens([token])
        }

        let model = WalletModel(walletManager: walletManager,
                                derivationStyle: derivationStyle)

        model.initialize()
        return model
    }

    func makeMultipleWallet(walletPublicKeys: [EllipticCurve: Data],
                            entry: StorageEntry,
                            derivationStyle: DerivationStyle) throws -> WalletModel {
        guard let walletPublicKey = walletPublicKeys[entry.blockchainNetwork.blockchain.curve] else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider().factory
        let walletManager = try factory.makeWalletManager(blockchain: entry.blockchainNetwork.blockchain,
                                                          walletPublicKey: walletPublicKey)

        walletManager.addTokens(entry.tokens)

        let model = WalletModel(walletManager: walletManager, derivationStyle: derivationStyle)
        model.initialize()
        return model
    }

    func makeMultipleWallets(walletPublicKeys: [EllipticCurve: Data],
                             entries: [StorageEntry],
                             derivationStyle: DerivationStyle) -> [WalletModel] {
        entries.compactMap { entry in
            do {
                return try makeMultipleWallet(walletPublicKeys: walletPublicKeys, entry: entry, derivationStyle: derivationStyle)
            } catch {
                print(error)
                return nil
            }
        }
    }

    func makeMultipleWallets(seedKeys: [EllipticCurve: Data],
                             entries: [StorageEntry],
                             derivedKeys: [Data: [DerivationPath: ExtendedPublicKey]],
                             derivationStyle: DerivationStyle) -> [WalletModel] {
        entries.compactMap { entry in
            do {
                return try makeMultipleWallet(seedKeys: seedKeys, entry: entry, derivedKeys: derivedKeys, derivationStyle: derivationStyle)
            } catch {
                print(error)
                return nil
            }
        }
    }

    func makeMultipleWallet(seedKeys: [EllipticCurve: Data],
                            entry: StorageEntry,
                            derivedKeys: [Data: [DerivationPath: ExtendedPublicKey]],
                            derivationStyle: DerivationStyle) throws -> WalletModel {
        guard let seedKey = seedKeys[entry.blockchainNetwork.blockchain.curve],
              let derivationPath = entry.blockchainNetwork.derivationPath,
              let derivedWalletKeys = derivedKeys[seedKey],
              let derivedKey = derivedWalletKeys[derivationPath] else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider().factory
        let walletManager = try factory.makeWalletManager(blockchain: entry.blockchainNetwork.blockchain,
                                                          seedKey: seedKey,
                                                          derivedKey: derivedKey,
                                                          derivation: .custom(derivationPath))
        walletManager.addTokens(entry.tokens)

        let model = WalletModel(walletManager: walletManager, derivationStyle: derivationStyle)
        model.initialize()
        return model
    }
}
