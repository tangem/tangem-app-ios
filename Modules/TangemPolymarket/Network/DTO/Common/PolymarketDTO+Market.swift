//
//  PolymarketDTO+Market.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct Market: Decodable {
        let id: String
        let question: String

        let groupItemTitle: String?

        let image: String?
        let icon: String?

        let status: String?
        let negRisk: Bool?

        let startDate: String?
        let endDate: String?
        let startDateIso: String?
        let endDateIso: String?

        let volume: Decimal?
        let volume24hr: Decimal?
        let liquidity: Decimal?

        let outcomes: [Outcome]?
    }
}
