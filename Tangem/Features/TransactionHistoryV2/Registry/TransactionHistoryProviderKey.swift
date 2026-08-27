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
    @available(iOS, deprecated: 100000.0, message: "Debug-only, do not use this property.")
    @IgnoredEquatable
    private(set) var tokenItem: TokenItem
}
