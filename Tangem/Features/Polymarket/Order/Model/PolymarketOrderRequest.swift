//
//  PolymarketOrderRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

enum PolymarketOrderRequest {
    case buy
    case sell(shares: Decimal)

    var side: PolymarketOrderSide {
        switch self {
        case .buy: .buy
        case .sell: .sell
        }
    }
}

// MARK: - Indexing

typealias PolymarketOrderIndexing = Task<PolymarketPosition?, Never>
