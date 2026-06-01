//
//  AccountSelectorMultipleAccountsItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import enum TangemUI.ThumbnailWalletViewType

/// Represents the accounts of a single wallet shown in the picker. Despite the "Multiple" in the
/// name, this type is also used for wallets with a single account — callers wrap that lone account
/// into a one-element `accounts` array. A follow-up rename is tracked separately.
struct AccountSelectorMultipleAccountsItem: Identifiable {
    let walletId: String
    let walletName: String
    let walletThumbnailType: ThumbnailWalletViewType?
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
        walletThumbnailType = userWallet.config.walletThumbnailType
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
