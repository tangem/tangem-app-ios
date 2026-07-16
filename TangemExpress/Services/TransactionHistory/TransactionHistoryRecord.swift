//
//  TransactionHistoryRecord.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
public protocol TransactionHistoryRecord: Sendable {
    var txId: String { get }
    var updatedAt: Date { get }
}
