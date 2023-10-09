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

    private func makeTransactionHistoryService(tokenItem: TokenItem, wallet: Wallet) -> TransactionHistoryService? {
        if FeatureStorage().useFakeTxHistory {
            return FakeTransactionHistoryService(blockchain: tokenItem.blockchain, address: wallet.address)
        }

        let factory = TransactionHistoryFactoryProvider().factory
        guard let provider = factory.makeProvider(for: tokenItem.blockchain) else {
            return nil
        }

        if wallet.addresses.count > 1 {
            return MutipleAddressTransactionHistoryService(
                tokenItem: tokenItem,
                addresses: wallet.addresses.map { $0.value },
                transactionHistoryProvider: provider
            )
        }

        return CommonTransactionHistoryService(
            tokenItem: tokenItem,
            address: wallet.address,
            transactionHistoryProvider: provider
        )
    }
}

extension CommonWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(from walletManager: WalletManager) -> [WalletModel] {
        var types: [Amount.AmountType] = [.coin]
        types += walletManager.cardTokens.map { Amount.AmountType.token(value: $0) }
        return makeWalletModels(for: types, walletManager: walletManager)
    }

    func makeWalletModels(for types: [Amount.AmountType], walletManager: WalletManager) -> [WalletModel] {
        var models: [WalletModel] = []

        let currentBlockchain = walletManager.wallet.blockchain
        let currentDerivation = walletManager.wallet.publicKey.derivationPath
        let isMainCoinCustom = !isDerivationDefault(blockchain: currentBlockchain, derivationPath: currentDerivation)
        let transactionHistoryService = makeTransactionHistoryService(
            tokenItem: .blockchain(currentBlockchain),
            wallet: walletManager.wallet
        )

        if types.contains(.coin) {
            let mainCoinModel = WalletModel(
                walletManager: walletManager,
                transactionHistoryService: transactionHistoryService,
                amountType: .coin,
                isCustom: isMainCoinCustom
            )
            models.append(mainCoinModel)
        }

        walletManager.cardTokens.forEach { token in
            let amountType: Amount.AmountType = .token(value: token)
            if types.contains(amountType) {
                let isTokenCustom = isMainCoinCustom || token.id == nil
                let transactionHistoryService = makeTransactionHistoryService(
                    tokenItem: .token(token, currentBlockchain),
                    wallet: walletManager.wallet
                )
                let tokenModel = WalletModel(
                    walletManager: walletManager,
                    transactionHistoryService: transactionHistoryService,
                    amountType: amountType,
                    isCustom: isTokenCustom
                )
                models.append(tokenModel)
            }
        }

        return models
    }
}
