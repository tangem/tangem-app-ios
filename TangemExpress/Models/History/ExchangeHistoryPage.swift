//
//  ExchangeHistoryPage.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeHistoryPage: Hashable {
    public let records: [ExchangeHistoryRecord]
    public let nextCursor: String
    /// Opaque cursor for the next page.
    public let hasMore: Bool
}
