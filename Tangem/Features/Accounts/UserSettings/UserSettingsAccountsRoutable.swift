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
        userWalletConfig: UserWalletConfig
    )

    func openManageTokens(
        accountModelsManager: any AccountModelsManager,
        cryptoAccountModel: any CryptoAccountModel,
        userWalletConfig: UserWalletConfig
    )

    func openAccountDetails(
        account: any BaseAccountModel,
        accountModelsManager: any AccountModelsManager,
        userWalletConfig: UserWalletConfig
    )

    func openArchivedAccounts(accountModelsManager: any AccountModelsManager)

    func handleAccountsLimitReached()

    func handleAccountsRedistribution(sourceAccountName: String, targetAccountName: String)
}
