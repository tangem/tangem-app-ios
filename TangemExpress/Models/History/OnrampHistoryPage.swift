//
//  OnrampHistoryPage.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampHistoryPage: Hashable {
    public let records: [OnrampHistoryRecord]
    /// Opaque cursor for the next sync. Persist as-is, do not parse.
    public let nextCursor: String
    /// `true` when more pages are immediately available; `false` means caller should stop paginating
    /// in this sync (but keep `nextCursor` for the next delta).
    public let hasMore: Bool
}
