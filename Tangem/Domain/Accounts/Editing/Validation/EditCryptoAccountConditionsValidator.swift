//
//  EditCryptoAccountConditionsValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct EditCryptoAccountConditionsValidator {
    let newAccountName: String?
    let derivationIndex: Int
    let remoteState: CryptoAccountsRemoteState
}

// MARK: - CryptoAccountConditionsValidator protocol conformance

extension EditCryptoAccountConditionsValidator: CryptoAccountConditionsValidator {
    typealias ValidationError = AccountEditError

    func validate() async throws(ValidationError) {
        guard let newAccountName else {
            return try validateMissingAccountName()
        }

        guard newAccountName.count <= AccountModelUtils.maxAccountNameLength else {
            AccountsLogger.warning("Account name is too long")
            throw .accountNameTooLong
        }

        let remoteState = makeRemoteState()
        let uniquenessChecker = CryptoAccountNameUniquenessChecker(remoteState: remoteState)

        guard uniquenessChecker.isNameUnique(newAccountName) else {
            AccountsLogger.warning("Account with the same name already exists")
            throw .duplicateAccountName
        }
    }

    private func validateMissingAccountName() throws(ValidationError) {
        if !AccountModelUtils.isMainAccount(derivationIndex) {
            // For non-main accounts, the name is always required
            throw .missingAccountName
        }
    }

    private func makeRemoteState() -> CryptoAccountsRemoteState {
        // Exclude the account being edited from the remote state to avoid false positives in name uniqueness check
        let accounts = remoteState
            .accounts
            .filter { $0.derivationIndex != derivationIndex }

        return CryptoAccountsRemoteState(
            nextDerivationIndex: remoteState.nextDerivationIndex,
            accounts: accounts
        )
    }
}
