//
//  PolymarketDTO+EventsSearchResponse.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension PolymarketDTO {
    struct EventsSearchResponse: Decodable {
        let events: [Event]
        let page: Int?
        let total: Int?
        let hasNext: Bool
    }
}
