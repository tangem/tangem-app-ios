//
//  PolymarketOrderFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketOrderFlowBuilder: AnyObject {
    func makeOrderCoordinator(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        request: PolymarketOrderRequest,
        onPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onOpenPosition: @escaping (PolymarketPosition) -> Void,
        onClose: @escaping () -> Void
    ) -> PolymarketOrderCoordinator

    func makePositionDetails(
        position: PolymarketPosition,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onRegionWarning: @escaping () -> Void,
        onOpenPosition: @escaping (PolymarketPosition) -> Void,
        onClose: @escaping Action<Void>
    ) -> PolymarketPositionDetailsCoordinator

    func returnToMain()
}
