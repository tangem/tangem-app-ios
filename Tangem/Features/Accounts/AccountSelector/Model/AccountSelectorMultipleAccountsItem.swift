//
//  AccountSelectorMultipleAccountsItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct AccountSelectorMultipleAccountsItem: Identifiable {
    let walletId: String
    let walletName: String
    var accounts: [AccountSelectorAccountItem]

    var id: String { walletId }
}

extension AccountSelectorMultipleAccountsItem: Equatable {
    init(userWallet: any UserWalletModel, accounts: [any CryptoAccountModel]) {
        walletId = userWallet.userWalletId.stringValue
        walletName = userWallet.name
        self.accounts = accounts.map { account in
            AccountSelectorAccountItem(
                id: "\(account.id)",
                walletId: userWallet.userWalletId.stringValue,
                name: userWallet.name,
                tokensCount: Localization.commonTokensCount(account.walletModelsManager.walletModels.count),
                icon: account.icon,
                domainModel: account
            )
        }
    }

    static func == (lhs: AccountSelectorMultipleAccountsItem, rhs: AccountSelectorMultipleAccountsItem) -> Bool {
        lhs.id == rhs.id
    }
}
