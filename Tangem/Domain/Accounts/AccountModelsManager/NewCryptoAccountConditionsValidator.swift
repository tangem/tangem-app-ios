//
//  NewCryptoAccountConditionsValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct NewCryptoAccountConditionsValidator {
    let newAccountName: String
    let remoteState: CryptoAccountsRemoteState

    func isValid() -> Bool {
        guard remoteState.accounts.count <= AccountModelUtils.maxNumberOfAccounts else {
            AccountsLogger.warning("Number of accounts exceeded the limit")
            return false
        }

        guard newAccountName.count <= AccountModelUtils.maxAccountNameLength else {
            AccountsLogger.warning("Account name is too long")
            return false
        }

        guard !remoteState.accounts.contains(where: { account in
            let existingAccountName = account.name?.trimmed()
            let newAccountName = newAccountName.trimmed()

            return existingAccountName?.compare(newAccountName) == .orderedSame
        }) else {
            AccountsLogger.warning("Account with the same name already exists")
            return false
        }

        return true
    }
}
