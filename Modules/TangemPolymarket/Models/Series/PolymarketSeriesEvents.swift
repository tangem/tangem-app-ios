//
//  PolymarketSeriesEvents.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct PolymarketSeriesEvents: Hashable, Sendable {
    public let seriesId: String
    public let events: [PolymarketEvent]

    public init(seriesId: String, events: [PolymarketEvent]) {
        self.seriesId = seriesId
        self.events = events
    }
}
