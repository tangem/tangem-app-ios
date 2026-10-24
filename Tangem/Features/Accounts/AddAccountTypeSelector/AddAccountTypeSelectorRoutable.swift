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

    /// - Note: Takes nothing: the joint account flow lets the user pick the wallet the account is created in, so
    /// the wallet the selector was opened from is only its starting point, which the coordinator already knows.
    func openJointAccountManagement()

    func dismissAddAccountTypeSelector()
}
