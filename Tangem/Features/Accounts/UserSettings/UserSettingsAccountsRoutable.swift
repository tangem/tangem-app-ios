//
//  UserSettingsAccountsRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol UserSettingsAccountsRoutable: AnyObject {
    func addNewAccount(userWalletId: UserWalletId, accountIndex: Int, accountModelsManager: any AccountModelsManager)
}
