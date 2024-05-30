//
//  MarketsListOrderType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsListOrderType: String, Encodable {
    case rating
    case trending
    case buyers
    case gainers
    case losers
}
