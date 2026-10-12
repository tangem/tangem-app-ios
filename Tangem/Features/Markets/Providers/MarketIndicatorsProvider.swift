//
//  MarketIndicatorsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketIndicatorsProvider {
    func indicators(currency: String) async throws -> MarketIndicators
}

struct MarketIndicators: Equatable {
    let totalMarketCap: Decimal?
    let marketCapChangePercentage24h: Decimal?
    let fearGreed: Indicator?
    let altcoinIndex: Indicator?
}

extension MarketIndicators {
    struct Indicator: Equatable {
        let value: Decimal
        let classification: String?
    }
}
