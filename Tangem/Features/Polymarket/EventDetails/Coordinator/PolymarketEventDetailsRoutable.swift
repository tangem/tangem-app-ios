//
//  PolymarketEventDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketEventDetailsRoutable: AnyObject {
    func dismissEventDetails()
    func openOrder(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        onPlaced: @escaping @MainActor (Task<Void, Never>?) -> Void
    )
    func openRegionWarning()
}
