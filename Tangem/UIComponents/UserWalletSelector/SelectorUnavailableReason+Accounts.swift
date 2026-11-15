//
//  SelectorUnavailableReason+Accounts.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccounts
import TangemLocalization

extension SelectorUnavailableReason {
    static func accountsLimitReached(for accountType: AccountType) -> SelectorUnavailableReason {
        SelectorUnavailableReason(
            badge: Localization.accountAddLimitBadge,
            title: Localization.accountAddLimitDialogTitle,
            message: Localization.accountAddLimitDialogDescription(AccountModelUtils.maxNumberOfAccounts(for: accountType))
        )
    }
}
