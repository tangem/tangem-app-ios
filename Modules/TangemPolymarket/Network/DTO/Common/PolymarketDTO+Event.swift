//
//  PolymarketDTO+Event.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct Event: Decodable {
        let eventId: String
        let slug: String
        let title: String
        let description: String?
        let polymarketRulesUrl: String?

        let image: String?
        let icon: String?

        let status: String?
        let live: Bool?
        let startDate: String?
        let endDate: String?

        let volume: Decimal?
        let volume24hr: Decimal?
        let liquidity: Decimal?

        let totalMarketsCount: Int?

        let negRisk: Bool?
        let displayMode: String?

        let markets: [Market]?

        let teams: [Team]?
    }

    struct Team: Decodable {
        let name: String?
        let abbreviation: String?
        let alias: String?
        let logo: String?
        let ordering: String?
    }
}
