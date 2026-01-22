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
        switch connectedDApp {
        case .v1(let dAppV1):
            try firstUserWallet(from: userWalletModels, with: { $0.userWalletId.stringValue == dAppV1.userWalletID })
        case .v2(let dAppV2):
            try firstUserWallet(from: userWalletModels) {
                let account = WCAccountFinder.findCryptoAccountModel(by: dAppV2.accountId, accountModelsManager: $0.accountModelsManager)

                return account != nil
            }
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
