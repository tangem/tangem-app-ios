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
            try firstUserWallet(from: userWalletModels) { userWalletModel in
                userWalletModel.userWalletId.stringValue == dAppV2.userWalletID
                    && findCryptoAccountModel(dAppV2: dAppV2, userWalletModel: userWalletModel) != nil
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

    private static func findCryptoAccountModel(
        dAppV2: WalletConnectConnectedDAppV2,
        userWalletModel: any UserWalletModel
    ) -> (any CryptoAccountModel)? {
        return WCAccountFinder.findCryptoAccountModel(by: dAppV2.accountId, accountModelsManager: userWalletModel.accountModelsManager)
    }
}
