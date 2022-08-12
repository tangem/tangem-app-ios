//
//  WalletModelBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

protocol WalletModelBuilder {}

extension WalletModelBuilder {
    func makeSingleWallet(card: Card, blockchain: Blockchain, token: BlockchainSdk.Token?) -> WalletModel? {
        guard let walletPublicKey = card.wallets.first(where: { $0.curve == defaultBlockchain.curve })?.publicKey else {
            return nil
        }

        do {
            let factory = WalletManagerFactoryProvider().factory
            let walletManager = try factory.makeWalletManager(blockchain: defaultBlockchain,
                                                              walletPublicKey: walletPublicKey)
            if let token = defaultToken {
                walletManager.addTokens([token])
            }

            let model = WalletModel(walletManager: walletManager,
                                    derivationStyle: card.derivationStyle)

            model.initialize()
            return model
        } catch {
            print(error)
            return nil
        }
    }

    func makeMultipleWallets(entries: [StorageEntry]) -> [WalletModel] {
        let factory = WalletManagerFactoryProvider().factory

        var models: [WalletModel] = []

        for entry in entries {
            do {
                if let wallet = card.wallets.first(where: { $0.curve == entry.blockchainNetwork.blockchain.curve }) {
                    let walletManager = try factory.makeWalletManager(blockchain: entry.blockchainNetwork.blockchain,
                                                                      walletPublicKey: wallet.publicKey)

                    walletManager.addTokens(entry.tokens)

                    let model = WalletModel(walletManager: walletManager, derivationStyle: card.derivationStyle)
                    model.initialize()
                    models.append(model)
                }
            } catch {
                print(error)
            }
        }

        return models
    }

    func makeMultipleWallets(entries: [StorageEntry], derivedKeys: [DerivationPath: ExtendedPublicKey]) -> [WalletModel] {
        let factory = WalletManagerFactoryProvider().factory

        var models: [WalletModel] = []

        for entry in entries {
            do {
                if let wallet = card.wallets.first(where: { $0.curve == entry.blockchainNetwork.blockchain.curve }),
                   let derivationPath = entry.blockchainNetwork.derivationPath,
                   let derivedKey = derivedKeys[derivationPath] {

                    let walletManager = try factory.makeWalletManager(blockchain: entry.blockchainNetwork.blockchain,
                                                                      seedKey: wallet.publicKey,
                                                                      derivedKey: derivedKey,
                                                                      derivation: .custom(derivationPath))
                    walletManager.addTokens(entry.tokens)

                    let model = WalletModel(walletManager: walletManager, derivationStyle: card.derivationStyle)
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
