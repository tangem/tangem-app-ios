//
//  CommonTransactionHistoryProviderRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
final class CommonTransactionHistoryProviderRegistry {}

// MARK: - TransactionHistoryProviderRegistry protocol conformance

extension CommonTransactionHistoryProviderRegistry: TransactionHistoryProviderRegistry {
    func provider(for key: TransactionHistoryProviderKey) -> any TransactionHistorySyncing {
        // [REDACTED_TODO_COMMENT]
        fatalError("\(Self.self).provider(for:) is not implemented")
    }
}
