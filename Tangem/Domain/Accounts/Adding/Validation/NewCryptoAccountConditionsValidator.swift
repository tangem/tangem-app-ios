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
}

// MARK: - CryptoAccountConditionsValidator protocol conformance

extension NewCryptoAccountConditionsValidator: CryptoAccountConditionsValidator {
    func validate() async throws {
        guard remoteState.accounts.count < AccountModelUtils.maxNumberOfAccounts else {
            AccountsLogger.warning("The number of accounts exceeded the limit")
            throw Error.tooManyAccounts
        }

        guard newAccountName.count <= AccountModelUtils.maxAccountNameLength else {
            AccountsLogger.warning("Account name is too long")
            throw Error.accountNameTooLong
        }

        guard !remoteState.contains(accountWithName: newAccountName) else {
            AccountsLogger.warning("Account with the same name already exists")
            throw Error.duplicateAccountName
        }
    }
}

// MARK: - Auxiliary types

extension NewCryptoAccountConditionsValidator {
    enum Error: Swift.Error {
        case tooManyAccounts
        case accountNameTooLong
        case duplicateAccountName
    }
}
