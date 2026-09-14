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

    @MainActor
    func openHowItWorks()

    func openEventDetails(eventID: String, category: PolymarketCategory?)

    func openPositionDetails(position: PolymarketPosition)

    func openOrder(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String)
}
