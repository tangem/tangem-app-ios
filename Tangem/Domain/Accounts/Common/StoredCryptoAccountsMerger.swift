//
//  StoredCryptoAccountsMerger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
struct StoredCryptoAccountsMerger {
    /// If true, the `tokens` field of accounts from the `oldAccounts` array will be preserved
    /// instead of being overwritten by the `token` field of accounts from the `newAccounts` array.
    let preserveTokens: Bool

    func merge(
        oldAccounts: [StoredCryptoAccount],
        newAccounts: [StoredCryptoAccount]
    ) -> (accounts: [StoredCryptoAccount], isDirty: Bool) {
        var updatedAccounts = oldAccounts
        var isDirty = false

        // Fast lookup dictionary to find existing accounts by their derivation index
        let indicesKeyedByDerivationIndex: [Int: Int] = oldAccounts
            .enumerated()
            .reduce(into: [:]) { partialResult, input in
                let (index, account) = input
                partialResult[account.derivationIndex] = index
            }

        for newAccount in newAccounts {
            if let targetIndex = indicesKeyedByDerivationIndex[newAccount.derivationIndex] {
                let existingAccount = updatedAccounts[targetIndex]

                // Exclude `tokens` field of new account from comparison if we need to preserve existing tokens
                let newAccount = preserveTokens
                    ? newAccount.withTokens(existingAccount.tokens)
                    : newAccount

                if existingAccount != newAccount {
                    isDirty = true
                }

                updatedAccounts[targetIndex] = newAccount
            } else {
                isDirty = true
                updatedAccounts.append(newAccount)
            }
        }

        return (updatedAccounts, isDirty)
    }
}
