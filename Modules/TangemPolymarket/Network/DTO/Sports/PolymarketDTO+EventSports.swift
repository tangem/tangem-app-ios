//
//  PolymarketDTO+EventSports.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct EventSports: Decodable {
        let tags: [Tag]?
        let markets: [Market]?

        struct Tag: Decodable {
            let slug: String?
        }

        struct Market: Decodable {
            let conditionId: String?
            let sportsMarketType: String?
        }
    }
}
