//
//  MarketIndicatorsTestSupport.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// Use this tag for all market indicator suites: @Suite(.tags(.marketIndicators))
extension Tag {
    @Tag static var marketIndicators: Self
}

// MARK: - Fixtures

enum MarketIndicatorsFixture {
    static func response(
        totalMarketCap: Decimal? = 3_500_000_000_000,
        marketCapChangePercentage24H: Decimal? = -1.25,
        fearGreedValue: Decimal? = 52,
        fearGreedClassification: String? = "Neutral",
        altcoinIndexValue: Decimal? = 30,
        altcoinIndexClassification: String? = "Bitcoin Season"
    ) -> MarketsDTO.MarketIndicators.Response {
        MarketsDTO.MarketIndicators.Response(
            totalMarketCap: totalMarketCap,
            marketCapChangePercentage24H: marketCapChangePercentage24H,
            fearGreedValue: fearGreedValue,
            fearGreedClassification: fearGreedClassification,
            altcoinIndexValue: altcoinIndexValue,
            altcoinIndexClassification: altcoinIndexClassification
        )
    }

    static func indicators(
        totalMarketCap: Decimal? = 3_500_000_000_000,
        marketCapChangePercentage24h: Decimal? = -1.25,
        fearGreed: MarketIndicators.Indicator? = .init(value: 52, classification: "Neutral"),
        altcoinIndex: MarketIndicators.Indicator? = .init(value: 30, classification: "Bitcoin Season")
    ) -> MarketIndicators {
        MarketIndicators(
            totalMarketCap: totalMarketCap,
            marketCapChangePercentage24h: marketCapChangePercentage24h,
            fearGreed: fearGreed,
            altcoinIndex: altcoinIndex
        )
    }
}

enum MarketIndicatorsTestError: Error, Equatable {
    case network
}
