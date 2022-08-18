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
                          derivationStyle: DerivationStyle) -> WalletModel? {
        do {
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
        } catch {
            print(error)
            return nil
        }
    }

    func makeMultipleWallets(walletPublicKeys: [EllipticCurve: Data],
                             entries: [StorageEntry],
                             derivationStyle: DerivationStyle) -> [WalletModel] {
        let factory = WalletManagerFactoryProvider().factory

        var models: [WalletModel] = []

        for entry in entries {
            do {
                if let walletPublicKey = walletPublicKeys[entry.blockchainNetwork.blockchain.curve] {
                    let walletManager = try factory.makeWalletManager(blockchain: entry.blockchainNetwork.blockchain,
                                                                      walletPublicKey: walletPublicKey)

                    walletManager.addTokens(entry.tokens)

                    let model = WalletModel(walletManager: walletManager, derivationStyle: derivationStyle)
                    model.initialize()
                    models.append(model)
                }
            } catch {
                print(error)
            }
        }

        return models
    }

    func makeMultipleWallets(seedKeys: [EllipticCurve: Data],
                             entries: [StorageEntry],
                             derivedKeys: [Data: [DerivationPath: ExtendedPublicKey]],
                             derivationStyle: DerivationStyle) -> [WalletModel] {
        let factory = WalletManagerFactoryProvider().factory

        var models: [WalletModel] = []

        for entry in entries {
            do {
                if let seedKey = seedKeys[entry.blockchainNetwork.blockchain.curve],
                   let derivationPath = entry.blockchainNetwork.derivationPath,
                   let derivedWalletKeys = derivedKeys[seedKey],
                   let derivedKey = derivedWalletKeys[derivationPath] {

                    let walletManager = try factory.makeWalletManager(blockchain: entry.blockchainNetwork.blockchain,
                                                                      seedKey: seedKey,
                                                                      derivedKey: derivedKey,
                                                                      derivation: .custom(derivationPath))
                    walletManager.addTokens(entry.tokens)

                    let model = WalletModel(walletManager: walletManager, derivationStyle: derivationStyle)
                    model.initialize()
                    models.append(model)
                }
            } catch {
                print(error)
            }
        }

        return models
    }
}
