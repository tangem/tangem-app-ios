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
        let total: Int
    }
}
