//
//  DummyTransactionHistoryProviderRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
@available(iOS, deprecated: 100000.0, message: "Dummy stub to satisfy the compiler, do not use")
struct DummyTransactionHistoryProviderRegistry: TransactionHistoryProviderRegistry {
    func provider(for key: TransactionHistoryProviderKey) async -> TransactionHistorySyncing {
        // This implementation is never be called at runtime when the feature toggle is off
        fatalError("Not implemented")
    }
}
