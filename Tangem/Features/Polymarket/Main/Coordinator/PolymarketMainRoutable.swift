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
    func openMyPositions(tab: PolymarketPositionsTab, onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void)

    func openAddFunds()

    @MainActor
    func openHowItWorks()

    func openWithdraw()

    func openEventDetails(
        eventID: String,
        category: PolymarketCategory?,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    )

    func openPositionDetails(position: PolymarketPosition, onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void)

    func openOrder(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        request: PolymarketOrderRequest,
        onPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    )
}
