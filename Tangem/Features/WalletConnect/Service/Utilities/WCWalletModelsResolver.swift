//
//  WCWalletModelsResolver.swift.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WCWalletModelsResolver {
    static func resolveWalletModels(
        account: (any CryptoAccountModel)?,
        userWalletModel: UserWalletModel
    ) throws(WalletConnectTransactionRequestProcessingError) -> [any WalletModel] {
        if FeatureProvider.isAvailable(.accounts) {
            guard let account else { throw .accountNotFound }

            return account.walletModelsManager.walletModels
        } else {
            return AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)
        }
    }

    static func resolveWalletModels(
        for accountId: String,
        userWalletModel: UserWalletModel
    ) throws(WalletConnectTransactionRequestProcessingError) -> [any WalletModel] {
        if FeatureProvider.isAvailable(.accounts) {
            guard
                let cryptoAccountModel = WCAccountFinder.findCryptoAccountModel(
                    by: accountId, accountModelsManager: userWalletModel.accountModelsManager
                )
            else {
                throw .accountNotFound
            }

            return cryptoAccountModel.walletModelsManager.walletModels
        } else {
            return AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)
        }
    }
}
