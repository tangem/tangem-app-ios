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

/// Polymarket indexes a fill a moment after the order goes through, so the screens that react to a
/// placed order wait on this rather than on the order itself. It resolves to `nil` when the position
/// never showed up.
typealias PolymarketOrderIndexing = Task<PolymarketPosition?, Never>
