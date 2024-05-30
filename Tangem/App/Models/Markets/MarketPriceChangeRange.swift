//
//  MarketPriceChangeRange.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum MarketPriceIntervalType: String, CaseIterable, Codable {
    case day = "24h"
    case week = "7d"
    case month = "1m"
}
