//
//  MarketsPriceIntervalType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsPriceIntervalType: String, CaseIterable, Codable, CustomStringConvertible, Identifiable, Equatable {
    case day = "24h"
    case week = "1w"
    case month = "30d"

    var id: Self {
        self
    }

    var description: String {
        rawValue
    }
}
