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

    public var hasNext: Bool {
        cursor != nil
    }

    public init(events: [PolymarketEvent], cursor: String?) {
        self.events = events
        self.cursor = cursor
    }
}
