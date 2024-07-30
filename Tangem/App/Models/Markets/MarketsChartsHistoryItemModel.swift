//
//  MarketsChartsHistoryItemModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
struct MarketsChartsHistoryItemModel: Decodable {
    /// `[timestamp (in milliseconds): price]`
    let prices: [String: Decimal]
}
