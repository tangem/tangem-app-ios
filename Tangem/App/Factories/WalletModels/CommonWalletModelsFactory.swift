//
//  CommonWalletModelsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct CommonWalletModelsFactory {
    private let derivationStyle: DerivationStyle?

    init(derivationStyle: DerivationStyle?) {
        self.derivationStyle = derivationStyle
    }

    private func isDerivationDefault(blockchain: Blockchain, derivationPath: DerivationPath?) -> Bool {
        guard let derivationStyle else {
            return true
        }

        let defaultDerivation = blockchain.derivationPath(for: derivationStyle)
        return derivationPath == defaultDerivation
    }
}

extension CommonWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(from walletManager: WalletManager) -> [WalletModel] {
        var types: [Amount.AmountType] = [.coin]
        let tokens = walletManager.cardTokens.map { Amount.AmountType.token(value: $0) }
        types.append(contentsOf: tokens)
        return makeWalletModels(for: types, walletManager: walletManager)
    }

    func makeWalletModels(for types: [Amount.AmountType], walletManager: WalletManager) -> [WalletModel] {
        var models: [WalletModel] = []

        let currentBlockchain = walletManager.wallet.blockchain
        let currentDerivation = walletManager.wallet.publicKey.derivationPath
        let isMainCoinCustom = !isDerivationDefault(blockchain: currentBlockchain, derivationPath: currentDerivation)

        if types.contains(.coin) {
            let mainCoinModel = WalletModel(walletManager: walletManager, amountType: .coin, isCustom: isMainCoinCustom)
            models.append(mainCoinModel)
        }

        walletManager.cardTokens.forEach { token in
            let amountType: Amount.AmountType = .token(value: token)
            if types.contains(amountType) {
                let isTokenCustom = isMainCoinCustom || token.id == nil
                let tokenModel = WalletModel(walletManager: walletManager, amountType: amountType, isCustom: isTokenCustom)
                models.append(tokenModel)
            }
        }

        return models
    }
}
