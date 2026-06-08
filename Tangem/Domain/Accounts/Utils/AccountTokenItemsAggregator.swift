//
//  AccountTokenItemsAggregator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AccountTokenItemsAggregator {
    static func tokenItems(from accountModelsManager: AccountModelsManager) -> [TokenItem] {
        accountModelsManager.accountModels.flatMap(tokenItems(from:))
    }

    static func tokenItems(from userWalletModels: [any UserWalletModel]) -> [TokenItem] {
        userWalletModels.flatMap { tokenItems(from: $0.accountModelsManager) }
    }

    private static func tokenItems(from accountModel: AccountModel) -> [TokenItem] {
        switch accountModel {
        case .standard(.single(let cryptoAccountModel)):
            return cryptoAccountModel.walletModelsManager.walletModels.map(\.tokenItem)
        case .standard(.multiple(let cryptoAccountModels)):
            return cryptoAccountModels.flatMap { $0.walletModelsManager.walletModels.map(\.tokenItem) }
        case .tangemPay(let tangemPayAccountModel):
            switch tangemPayAccountModel.state {
            case .tangemPayAccount(let tangemPayAccount):
                return [tangemPayAccount.paymentTokenItem]
            default:
                return []
            }
        }
    }
}
