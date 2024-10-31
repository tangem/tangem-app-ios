//
//  MarketsChartModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsChartModel: Decodable {
    /// `[timestamp (in milliseconds): price]`
    let prices: [String: Decimal]
}
