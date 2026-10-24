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
    let accountType: AccountType
    let remoteState: CryptoAccountsRemoteState
}

// MARK: - CryptoAccountConditionsValidator protocol conformance

extension NewCryptoAccountConditionsValidator: CryptoAccountConditionsValidator {
    typealias ValidationError = AccountEditError

    func validate() async throws(ValidationError) {
        guard !AccountModelUtils.isAccountsLimitReached(for: accountType, in: remoteState) else {
            AccountsLogger.warning("The number of accounts exceeded the limit")
            throw .tooManyAccounts
        }

        guard AccountModelUtils.isAccountNameValid(newAccountName) else {
            throw .invalidAccountName
        }

        guard CryptoAccountNameUniquenessChecker(remoteState: remoteState).isNameUnique(newAccountName) else {
            AccountsLogger.warning("Account with the same name already exists")
            throw .duplicateAccountName
        }
    }
}
