//
//  ExchangeHistoryPage.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemFoundation.IgnoredEquatable

public struct ExchangeHistoryPage: Hashable {
    public let records: [ExchangeHistoryRecord]

    /// Opaque cursor (hence `Any`) for the next page.
    @IgnoredEquatable
    public private(set) var nextCursor: Any?

    /// Opaque cursor (hence `Any`) to seed the delta sync; only the initial endpoint provides it.
    @IgnoredEquatable
    public private(set) var startDeltaCursor: Any?

    public let hasMore: Bool

    /// Needed because `private(set)` on `nextCursor` makes the synthesized memberwise init private.
    init(records: [ExchangeHistoryRecord], nextCursor: Any?, startDeltaCursor: Any?, hasMore: Bool) {
        self.records = records
        self.nextCursor = nextCursor
        self.startDeltaCursor = startDeltaCursor
        self.hasMore = hasMore
    }
}
