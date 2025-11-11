//
//  CryptoAccountsRemoteState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CryptoAccountsRemoteState {
    /// Index for the derivation path to be used when creating a new account.
    let nextDerivationIndex: Int
    let accounts: [StoredCryptoAccount]
}

// MARK: - Convenience extensions

extension CryptoAccountsRemoteState {
    func contains(accountWithName accountName: String) -> Bool {
        return accounts.contains { account in
            let existingAccountName = account.name?.trimmed()
            let newAccountName = accountName.trimmed()

            return existingAccountName?.compare(newAccountName) == .orderedSame
        }
    }
}
