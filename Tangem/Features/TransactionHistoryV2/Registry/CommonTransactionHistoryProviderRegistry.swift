//
//  CommonTransactionHistoryProviderRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Registry for transaction history providers used, single instance per user wallet model.
/// Transaction history providers are keyed by `TransactionHistoryProviderKey`.
actor CommonTransactionHistoryProviderRegistry {
    private var providers: [TransactionHistoryProviderKey: TransactionHistoryProvider] = [:]
}

// MARK: - TransactionHistoryProviderRegistry protocol conformance

extension CommonTransactionHistoryProviderRegistry: TransactionHistoryProviderRegistry {
    func provider(for key: TransactionHistoryProviderKey) -> any TransactionHistorySyncing {
        if let existing = providers[key] {
            return existing
        }

        let new = TransactionHistoryProvider(key: key)
        providers[key] = new

        return new
    }
}
