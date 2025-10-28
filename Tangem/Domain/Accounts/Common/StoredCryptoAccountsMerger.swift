//
//  StoredCryptoAccountsMerger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum StoredCryptoAccountsMerger {
    static func merge(
        oldAccounts: [StoredCryptoAccount],
        newAccounts: [StoredCryptoAccount]
    ) -> (accounts: [StoredCryptoAccount], isDirty: Bool) {
        var editedAccounts = oldAccounts
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
                isDirty = editedAccounts[targetIndex] != newAccount
                editedAccounts[targetIndex] = newAccount
            } else {
                isDirty = true
                editedAccounts.append(newAccount)
            }
        }

        return (editedAccounts, isDirty)
    }
}
