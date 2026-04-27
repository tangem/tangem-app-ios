//
//  MarketsTokenDetailsMetrics.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsMetrics: Codable, Equatable {
    let marketRating: Int?
    let marketRatingChange24H: Int?
    let circulatingSupply: Decimal?
    let marketCap: Decimal?
    let volume24H: Decimal?
    let totalSupply: Decimal?
    let maxSupply: Decimal?
    let fullyDilutedValuation: Decimal?
}
