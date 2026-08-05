//
//  AddAccountTypeSelectorRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol AddAccountTypeSelectorRoutable: AnyObject {
    func openCryptoAccountForm(
        accountModelsManager: any AccountModelsManager,
        userWalletConfig: UserWalletConfig
    )

    func openJointAccountManagement(
        accountModelsManager: any AccountModelsManager,
        userWalletConfig: UserWalletConfig
    )

    func dismissAddAccountTypeSelector()
}
