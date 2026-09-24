//
//  PolymarketOrderSide.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketOrderSide: String, Hashable, Sendable {
    case buy = "BUY"
    case sell = "SELL"

    var wireValue: UInt64 {
        switch self {
        case .buy: 0
        case .sell: 1
        }
    }

    var matchingBookSide: PolymarketOrderSide {
        switch self {
        case .buy: .sell
        case .sell: .buy
        }
    }
}
