//
//  RemoteCryptoAccountsInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct RemoteCryptoAccountsInfo {
    let counters: Counters
    let accounts: [StoredCryptoAccount]
    let legacyTokens: [StoredCryptoAccount.Token]
    let legacyGrouping: StoredCryptoAccount.Grouping
    let legacySorting: StoredCryptoAccount.Sorting
}

// MARK: - Inner types

extension RemoteCryptoAccountsInfo {
    struct Counters {
        let archived: Int
        /// Each type of account takes derivation indices from a counter of its own, since the two derive their keys
        /// from different coin types and their indices are unrelated.
        let crypto: Int
        /// Nil until the endpoint counts the types apart. The whole total stands in for the crypto counter meanwhile,
        /// which is what the endpoint counts today, but it is no count of joint accounts.
        let joint: Int?
    }
}
