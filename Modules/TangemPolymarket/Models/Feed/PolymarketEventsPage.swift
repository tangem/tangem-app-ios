//
//  PolymarketEventsPage.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct PolymarketEventsPage: Hashable, Sendable {
    public let events: [PolymarketEvent]

    public let cursor: String?

    public let hasNext: Bool

    public init(events: [PolymarketEvent], cursor: String?, hasNext: Bool) {
        self.events = events
        self.cursor = cursor
        self.hasNext = hasNext
    }
}
