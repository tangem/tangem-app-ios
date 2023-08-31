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

    private func makeTransactionHistoryService(tokenItem: TokenItem, address: String) -> TransactionHistoryService? {
        if FeatureStorage().useFakeTxHistory {
            return FakeTransactionHistoryService(blockchain: tokenItem.blockchain, address: address)
        }

        let factory = TransactionHistoryFactoryProvider().factory
        guard let provider = factory.makeProvider(for: tokenItem.blockchain) else {
            return nil
        }

        return CommonTransactionHistoryService(
            tokenItem: tokenItem,
            address: address,
            transactionHistoryProvider: provider
        )
    }
}

extension CommonWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(from walletManager: WalletManager) -> [WalletModel] {
        let currentBlockchain = walletManager.wallet.blockchain
        let currentDerivation = walletManager.wallet.publicKey.derivationPath
        let isMainCoinCustom = !isDerivationDefault(blockchain: currentBlockchain, derivationPath: currentDerivation)
        let transactionHistoryService = makeTransactionHistoryService(
            tokenItem: .blockchain(currentBlockchain),
            address: walletManager.wallet.address
        )

        let mainCoinModel = WalletModel(
            walletManager: walletManager,
            transactionHistoryService: transactionHistoryService,
            amountType: .coin,
            isCustom: isMainCoinCustom
        )

        let tokenModels = walletManager.cardTokens.map { token in
            let amountType: Amount.AmountType = .token(value: token)
            let isTokenCustom = isMainCoinCustom || token.id == nil
            let transactionHistoryService = makeTransactionHistoryService(
                tokenItem: .token(token, currentBlockchain),
                address: walletManager.wallet.address
            )
            let tokenModel = WalletModel(
                walletManager: walletManager,
                transactionHistoryService: transactionHistoryService,
                amountType: amountType,
                isCustom: isTokenCustom
            )
            return tokenModel
        }

        return [mainCoinModel] + tokenModels
    }
}
