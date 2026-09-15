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

    @MainActor
    func openMyPositions(tab: PolymarketPositionsTab)

    func openAddFunds()

    @MainActor
    func openHowItWorks()

    func openWithdraw()

    func openEventDetails(
        eventID: String,
        category: PolymarketCategory?,
        onOrderPlaced: @escaping @MainActor (Task<Void, Never>?) -> Void
    )

    func openPositionDetails(position: PolymarketPosition)

    func openOrder(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        onPlaced: @escaping @MainActor (Task<Void, Never>?) -> Void
    )
}
