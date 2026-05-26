//
//  InMemoryHistoryCursorStorage.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
actor InMemoryHistoryCursorStorage {
    private var stored: Any?

    init(walletAddress: String) {
        _ = walletAddress
    }
}

// MARK: - HistoryCursorStorage protocol conformance

extension InMemoryHistoryCursorStorage: HistoryCursorStorage {
    var cursor: Any? { stored }

    func setCursor(_ cursor: Any?) {
        stored = cursor
    }

    func clear() {
        stored = nil
    }
}
