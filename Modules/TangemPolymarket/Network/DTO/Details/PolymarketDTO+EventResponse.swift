//
//  PolymarketDTO+EventResponse.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension PolymarketDTO {
    struct EventResponse: Decodable {
        let event: Event
    }
}
