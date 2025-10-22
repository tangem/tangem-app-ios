//
//  AccountSelectorMultipleAccountsItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct AccountSelectorMultipleAccountsItem: Identifiable, Hashable {
    let walletId: String
    let walletName: String
    let accounts: [AccountSelectorAccountItem]

    var id: String { walletId }
}

extension AccountSelectorMultipleAccountsItem {
    init(userWallet: any UserWalletModel, accountModel: AccountModel) {
        walletId = userWallet.userWalletId.stringValue
        walletName = userWallet.name

        switch accountModel {
        case .standard(.single(let account)):
            accounts = [.init(userWallet: userWallet, account: account)]
        case .standard(.multiple(let accounts)):
            self.accounts = accounts.map { .init(userWallet: userWallet, account: $0) }
        }
    }
}
