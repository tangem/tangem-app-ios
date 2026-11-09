//
//  PolymarketDTO+PriceHistory.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct PriceHistoryResponse: Decodable {
        let history: [Point]

        struct Point: Decodable {
            let timestamp: TimeInterval
            let price: Decimal

            enum CodingKeys: String, CodingKey {
                case timestamp = "t"
                case price = "p"
            }
        }
    }
}
