//
//  WCAccountFinder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WCAccountFinder {
    static func findCryptoAccountModel(
        by accountId: String,
        accountModelsManager: AccountModelsManager
    ) -> (any CryptoAccountModel)? {
        for accountModel in accountModelsManager.accountModels {
            switch accountModel {
            case .standard(.single(let cryptoAccountModel)):
                if cryptoAccountModel.id.walletConnectIdentifierString == accountId {
                    return cryptoAccountModel
                }
            case .standard(.multiple(let cryptoAccountModels)):
                if let cryptoAccountModel = cryptoAccountModels.first(where: {
                    $0.id.walletConnectIdentifierString == accountId
                }) {
                    return cryptoAccountModel
                }
            case .tangemPay, .polymarket:
                break
            }
        }

        return nil
    }
}
