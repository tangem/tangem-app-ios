//
//  SingleWalletModelsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SingleWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(for token: StorageEntry, keys: [CardDTO.Wallet]) throws -> [WalletModel] {
        let blockchain = token.blockchainNetwork.blockchain

        guard let walletPublicKey = keys.first(where: { $0.curve == blockchain.curve })?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider().factory

        let walletManager = try factory.makeWalletManager(
            blockchain: blockchain,
            walletPublicKey: walletPublicKey
        )

        let mainCoinModel = WalletModel(walletManager: walletManager, amountType: .coin, isCustom: false)

        if let token = token.tokens.first {
            walletManager.addTokens([token])
            let tokenModel = WalletModel(walletManager: walletManager, amountType: .token(value: token), isCustom: false)
            return [mainCoinModel, tokenModel]
        }

        return [mainCoinModel]
    }
}
