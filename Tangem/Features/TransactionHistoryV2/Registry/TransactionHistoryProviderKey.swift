//
//  TransactionHistoryProviderKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

// [REDACTED_TODO_COMMENT]
struct TransactionHistoryProviderKey: Sendable, Hashable {
    let address: String

    /// - Note: Debug-only property, not used for equality check or hashing. Should be ignored in tests.
    @IgnoredEquatable
    private(set) var tokenItem: TokenItem
}
