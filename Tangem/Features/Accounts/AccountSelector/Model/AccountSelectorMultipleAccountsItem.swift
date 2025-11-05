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
    init(userWallet: any UserWalletModel, accounts: [AccountSelectorAccountItem]) {
        walletId = userWallet.userWalletId.stringValue
        walletName = userWallet.name
        self.accounts = accounts
    }
}
