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
    let accounts: [AccountEntry]

    var id: String { walletId }

    struct AccountEntry: Identifiable {
        let item: AccountSelectorAccountItem
        let rowViewModel: AccountRowButtonViewModel

        var id: AnyHashable { item.id }
    }
}

extension AccountSelectorMultipleAccountsItem {
    init(
        userWallet: any UserWalletModel,
        accounts: [AccountSelectorAccountItem],
        onSelect: @escaping (AccountSelectorAccountItem) -> Void
    ) {
        walletId = userWallet.userWalletId.stringValue
        walletName = userWallet.name
        self.accounts = accounts.map { item in
            AccountEntry(
                item: item,
                rowViewModel: AccountRowButtonViewModel(
                    accountModel: item.domainModel,
                    availability: item.availability,
                    onTap: { onSelect(item) }
                )
            )
        }
    }
}
