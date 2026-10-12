//
//  MarketsDTO+MarketIndicators.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension MarketsDTO {
    enum MarketIndicators {}
}

extension MarketsDTO.MarketIndicators {
    struct Request {
        let currency: String
        let language: String

        var parameters: [String: Any] {
            ["currency": currency, "language": language]
        }
    }

    struct Response: Decodable {
        let totalMarketCap: Decimal?
        /// `24H`, not `24h`: the shared decoder converts from snake case, and that capitalises
        /// the `h` of `market_cap_change_percentage_24h`.
        let marketCapChangePercentage24H: Decimal?
        let fearGreedValue: Decimal?
        let fearGreedClassification: String?
        let altcoinIndexValue: Decimal?
        let altcoinIndexClassification: String?
    }
}
