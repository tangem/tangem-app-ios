//
//  AddAccountTypeSelectorRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol AddAccountTypeSelectorRoutable: AnyObject {
    func openCryptoAccountForm()

    /// - Note: Takes nothing: which wallet the account is created in is settled by the coordinator, which knows where
    /// the selector was opened from.
    func openJointAccountManagement()
}
