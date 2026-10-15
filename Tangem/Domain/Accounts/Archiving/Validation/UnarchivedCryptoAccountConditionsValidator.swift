//
//  UnarchivedCryptoAccountConditionsValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct UnarchivedCryptoAccountConditionsValidator {
    let newAccountName: String
    let identifier: any AccountModelPersistentIdentifierConvertible
    let accountType: AccountType
    let remoteState: CryptoAccountsRemoteState
}

// MARK: - CryptoAccountConditionsValidator protocol conformance

extension UnarchivedCryptoAccountConditionsValidator: CryptoAccountConditionsValidator {
    typealias ValidationError = AccountRecoveryError

    func validate() async throws(ValidationError) {
        guard !AccountModelUtils.isAccountsLimitReached(for: accountType, in: remoteState) else {
            AccountsLogger.warning("The number of accounts exceeded the limit")
            throw .tooManyAccounts
        }

        guard CryptoAccountNameUniquenessChecker(remoteState: remoteState).isNameUnique(newAccountName) else {
            // It's a recoverable error in this flow, therefore no logging needed here
            throw .duplicateAccountName
        }
    }
}
