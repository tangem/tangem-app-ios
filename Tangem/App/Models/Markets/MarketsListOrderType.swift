//
//  MarketsListOrderType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsListOrderType: String, CaseIterable, Encodable, CustomStringConvertible, Identifiable {
    case rating
    case trending
    case buyers
    case gainers
    case losers

    var id: String {
        rawValue
    }

    var description: String {
        switch self {
        // [REDACTED_TODO_COMMENT]
        default:
            return rawValue
        }
    }
}
