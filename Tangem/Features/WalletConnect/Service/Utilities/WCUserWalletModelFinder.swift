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
        let userWalletModel = userWalletModels.first { userWalletModel in
            userWalletModel.userWalletId.stringValue == connectedDApp.userWalletID
                && WCAccountFinder.findCryptoAccountModel(
                    by: connectedDApp.accountId,
                    accountModelsManager: userWalletModel.accountModelsManager
                ) != nil
        }

        guard let userWalletModel else {
            throw WalletConnectTransactionRequestProcessingError.userWalletNotFound
        }

        return userWalletModel
    }
}
