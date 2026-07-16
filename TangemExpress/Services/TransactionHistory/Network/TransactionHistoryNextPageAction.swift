//
//  TransactionHistoryNextPageAction.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum TransactionHistoryNextPageAction: Sendable {
    /// Page handled successfully — advance the cursor and fetch the next page (if any).
    case proceed
    /// Stop without advancing the cursor; the current page is retried on the next sync.
    case stop
}
