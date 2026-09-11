//
//  PolymarketEventDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPolymarket

protocol PolymarketEventDetailsRoutable: AnyObject {
    func dismissEventDetails()
    func openOrder(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String)
    func openRegionWarning()
}
