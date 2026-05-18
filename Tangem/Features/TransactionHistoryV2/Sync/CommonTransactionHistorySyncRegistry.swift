//
//  CommonTransactionHistorySyncRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
final class CommonTransactionHistorySyncRegistry {}

// MARK: - TransactionHistorySyncRegistry protocol conformance

extension CommonTransactionHistorySyncRegistry: TransactionHistorySyncRegistry {
    func sync(for key: TransactionHistorySyncKey) -> any TransactionHistorySyncing {
        // [REDACTED_TODO_COMMENT]
        fatalError("\(Self.self).sync(for:) is not implemented")
    }
}
