//
//  AccountsAwareAddTokenAccountDataProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts
import TangemLocalization

/// Reusable data provider for AccountsAwareAddTokenViewModel account/wallet selector
struct AccountsAwareAddTokenAccountDataProvider: AccountsAwareAddTokenAccountWalletSelectorDataProvider {
    let isSelectionAvailable: Bool
    let displayTitle: String
    let handleSelection: () -> Void
    let trailingContent: AccountsAwareAddTokenViewModel.AccountWalletTrailingContent

    init(
        isSelectionAvailable: Bool,
        accountSelectorCell: AccountSelectorCellModel,
        handleSelection: @escaping () -> Void
    ) {
        self.isSelectionAvailable = isSelectionAvailable
        self.handleSelection = handleSelection

        let account: any CryptoAccountModel
        switch accountSelectorCell {
        case .account(let accountItem):
            account = accountItem.domainModel
            displayTitle = Localization.accountDetailsTitle
            trailingContent = .account(
                AccountModelUtils.UI.iconViewData(accountModel: account),
                name: account.name
            )

        case .wallet(let walletItem):
            account = walletItem.mainAccount
            displayTitle = Localization.wcCommonWallet
            trailingContent = .walletName(walletItem.name)
        }
    }
}
