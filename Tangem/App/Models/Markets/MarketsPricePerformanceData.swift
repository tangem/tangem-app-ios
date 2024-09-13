//
//  MarketsPricePerformanceData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsPricePerformanceData: Codable, Equatable {
    let lowPrice: Decimal?
    let highPrice: Decimal?
}
