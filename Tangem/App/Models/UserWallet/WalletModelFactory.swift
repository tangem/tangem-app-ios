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
                          derivationStyle: DerivationStyle?) throws -> WalletModel {
        let factory = WalletManagerFactoryProvider().factory
        let walletManager = try factory.makeWalletManager(blockchain: blockchain,
                                                          walletPublicKey: walletPublicKey)
        if let token = token {
            walletManager.addTokens([token])
        }

        return WalletModel(walletManager: walletManager, derivationStyle: derivationStyle)
    }

    func makeMultipleWallet(walletPublicKeys: [EllipticCurve: Data],
                            entry: StorageEntry,
                            derivationStyle: DerivationStyle?) throws -> WalletModel {
        guard let walletPublicKey = walletPublicKeys[entry.blockchainNetwork.blockchain.curve] else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider().factory
        let walletManager = try factory.makeWalletManager(blockchain: entry.blockchainNetwork.blockchain,
                                                          walletPublicKey: walletPublicKey)

        walletManager.addTokens(entry.tokens)
        return WalletModel(walletManager: walletManager, derivationStyle: derivationStyle)
    }

    func makeMultipleWallet(seedKeys: [EllipticCurve: Data],
                            entry: StorageEntry,
                            derivedKeys: [EllipticCurve: [DerivationPath: ExtendedPublicKey]],
                            derivationStyle: DerivationStyle?) throws -> WalletModel {
        let curve = entry.blockchainNetwork.blockchain.curve
        
        guard let derivationPath = entry.blockchainNetwork.derivationPath else {
            throw CommonError.noData
        }

        guard let seedKey = seedKeys[curve],
              let derivedWalletKeys = derivedKeys[curve],
              let derivedKey = derivedWalletKeys[derivationPath] else {
            throw Errors.notDerivation
        }

        let factory = WalletManagerFactoryProvider().factory
        let walletManager = try factory.makeWalletManager(blockchain: entry.blockchainNetwork.blockchain,
                                                          seedKey: seedKey,
                                                          derivedKey: derivedKey,
                                                          derivation: .custom(derivationPath))
        walletManager.addTokens(entry.tokens)
        return WalletModel(walletManager: walletManager, derivationStyle: derivationStyle)
    }
}

extension WalletModelFactory {
    enum Errors: Error {
        case notDerivation
    }
}
