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
    public let nextCursor: String
    /// Opaque cursor for the next page.
    public let hasMore: Bool
}
