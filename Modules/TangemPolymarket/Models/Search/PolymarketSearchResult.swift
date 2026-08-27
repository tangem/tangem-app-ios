//
//  PolymarketSearchResult.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct PolymarketSearchResult: Hashable, Sendable {
    public let events: [PolymarketEvent]

    public let page: Int?

    public let total: Int?

    public let hasNext: Bool

    public init(events: [PolymarketEvent], page: Int?, total: Int?, hasNext: Bool) {
        self.events = events
        self.page = page
        self.total = total
        self.hasNext = hasNext
    }
}
