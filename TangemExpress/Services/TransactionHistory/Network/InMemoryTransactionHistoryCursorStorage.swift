//
//  InMemoryTransactionHistoryCursorStorage.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
actor InMemoryTransactionHistoryCursorStorage {
    private var stored: Any?
}

// MARK: - TransactionHistoryCursorStorage protocol conformance

extension InMemoryTransactionHistoryCursorStorage: TransactionHistoryCursorStorage {
    var cursor: Any? { stored }

    func setCursor(_ cursor: Any?) {
        stored = cursor
    }

    func clear() {
        stored = nil
    }
}
