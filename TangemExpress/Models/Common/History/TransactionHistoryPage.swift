//
//  TransactionHistoryPage.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemFoundation.IgnoredEquatable

/// - Note: `@unchecked Sendable` because the opaque (`Any?`) cursors aren't statically `Sendable`; every
///   stored value is immutable and `Record` is `Sendable` (`TransactionHistoryRecord: Sendable`).
public struct TransactionHistoryPage<Record: TransactionHistoryRecord>: @unchecked Sendable {
    public let records: [Record]

    /// Opaque cursor (hence `Any`) for the next page.
    @IgnoredEquatable
    public private(set) var nextCursor: Any?

    /// Opaque cursor (hence `Any`) to seed the delta sync.
    @IgnoredEquatable
    public private(set) var startDeltaCursor: Any?

    public let hasMore: Bool

    /// Needed because `private(set)` on the cursors makes the synthesized memberwise init private.
    init(records: [Record], nextCursor: Any?, startDeltaCursor: Any?, hasMore: Bool) {
        self.records = records
        self.nextCursor = nextCursor
        self.startDeltaCursor = startDeltaCursor
        self.hasMore = hasMore
    }
}

// MARK: - Equatable protocol conformance

extension TransactionHistoryPage: Equatable where Record: Equatable {}

// MARK: - Hashable protocol conformance

extension TransactionHistoryPage: Hashable where Record: Hashable {}
