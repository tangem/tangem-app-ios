//
//  MarketsChartsHistoryItemModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsChartsHistoryItemModel: Decodable {
    let prices: [String: Decimal]
}
