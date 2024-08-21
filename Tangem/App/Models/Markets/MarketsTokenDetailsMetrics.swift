//
//  MarketsTokenDetailsMetrics.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsMetrics: Codable {
    let marketRating: Int?
    let circulatingSupply: Decimal?
    let marketCap: Decimal?
    let volume24H: Decimal?
    let totalSupply: Decimal?
    let fullyDilutedValuation: Decimal?
}
