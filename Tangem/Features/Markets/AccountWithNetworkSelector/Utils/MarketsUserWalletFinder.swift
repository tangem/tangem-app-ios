//
//  MarketsUserWalletFinder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsUserWalletFinder {
    /// Finds the userWalletModel that contains the given crypto account
    static func findUserWalletModel(
        for cryptoAccount: any CryptoAccountModel,
        in userWalletModels: [UserWalletModel]
    ) -> UserWalletModel? {
        userWalletModels.first { userWalletModel in
            guard case .standard(let cryptoAccounts) = userWalletModel.accountModelsManager.accountModels.standard() else {
                return false
            }

            switch cryptoAccounts {
            case .single(let account):
                return account.id == cryptoAccount.id

            case .multiple(let accounts):
                return accounts.contains(where: { $0.id == cryptoAccount.id })
            }
        }
    }
}
