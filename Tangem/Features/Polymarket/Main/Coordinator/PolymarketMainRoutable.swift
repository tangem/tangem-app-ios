//
//  PolymarketMainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketMainRoutable: AnyObject {
    func dismiss()

    func openRegionWarning()

    func openAddFunds()

    func openEventDetails(eventID: String, category: PolymarketCategory?)

    func openOrder(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String)
}
