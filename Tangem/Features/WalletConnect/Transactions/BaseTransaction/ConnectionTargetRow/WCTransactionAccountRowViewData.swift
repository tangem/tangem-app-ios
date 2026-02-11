//
//  WCTransactionAccountRowViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccounts

struct WCTransactionAccountRowViewData {
    let accountName: String
    let iconViewData: AccountIconView.ViewData

    init?(account: (any CryptoAccountModel)?) {
        guard let account else { return nil }
        accountName = account.name
        iconViewData = AccountModelUtils.UI.iconViewData(accountModel: account)
    }
}
