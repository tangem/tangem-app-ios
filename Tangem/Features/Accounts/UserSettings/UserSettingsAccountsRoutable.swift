//
//  UserSettingsAccountsRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol UserSettingsAccountsRoutable: AnyObject {
    func addNewAccount(
        accountModelsManager: any AccountModelsManager,
        accountsCount: Int
    )

    func openAccountDetails(account: any BaseAccountModel, accountModelsManager: AccountModelsManager)
}
