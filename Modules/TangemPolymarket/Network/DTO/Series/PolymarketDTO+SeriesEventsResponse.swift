//
//  PolymarketDTO+SeriesEventsResponse.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension PolymarketDTO {
    struct SeriesEventsResponse: Decodable {
        let events: [Event]
        let seriesId: String
    }
}
