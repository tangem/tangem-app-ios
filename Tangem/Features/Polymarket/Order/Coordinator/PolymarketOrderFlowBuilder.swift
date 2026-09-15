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
        onPlaced: @escaping @MainActor (Task<Void, Never>?) -> Void,
        onClose: @escaping () -> Void
    ) -> PolymarketOrderCoordinator?
}
