//
//  WCUserWalletModelFinder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WCUserWalletModelFinder {
    static func findUserWalletModel(
        connectedDApp: WalletConnectConnectedDApp,
        userWalletModels: [any UserWalletModel]
    ) throws(WalletConnectTransactionRequestProcessingError) -> any UserWalletModel {
        let userWalletId = connectedDApp.userWalletID
        let accountId = connectedDApp.accountId

        return switch (userWalletId, accountId) {
        case (let userWalletId?, _):
            try firstUserWallet(from: userWalletModels, with: { $0.userWalletId.stringValue == userWalletId })
        case (_, let accountId?):
            try firstUserWallet(from: userWalletModels) {
                let account = WCAccountFinder.findCryptoAccountModel(by: accountId, accountModelsManager: $0.accountModelsManager)

                return account != nil
            }
        default:
            throw WalletConnectTransactionRequestProcessingError.userWalletNotFound
        }
    }

    private static func firstUserWallet(
        from userWalletModels: [any UserWalletModel],
        with condition: (any UserWalletModel) -> Bool
    ) throws(WalletConnectTransactionRequestProcessingError) -> any UserWalletModel {
        guard let userWalletModel = userWalletModels.first(where: condition) else {
            throw WalletConnectTransactionRequestProcessingError.userWalletNotFound
        }

        return userWalletModel
    }
}
