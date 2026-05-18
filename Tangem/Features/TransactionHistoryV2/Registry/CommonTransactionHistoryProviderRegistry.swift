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
final class CommonTransactionHistoryProviderRegistry {}

// MARK: - TransactionHistoryProviderRegistry protocol conformance

extension CommonTransactionHistoryProviderRegistry: TransactionHistoryProviderRegistry {
    func provider(for key: TransactionHistoryProviderKey) -> any TransactionHistorySyncing {
        fatalError("\(Self.self).provider(for:) is not implemented")
    }
}
