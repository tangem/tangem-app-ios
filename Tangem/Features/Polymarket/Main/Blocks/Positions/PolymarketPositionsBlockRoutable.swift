//
//  PolymarketPositionsBlockRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketPositionsBlockRoutable: AnyObject {
    @MainActor
    func openMyPositions(
        tab: PolymarketPositionsTab,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onClaimed: @escaping (PolymarketPosition?) -> Void
    )

    @MainActor
    func openRedeem(position: PolymarketPosition, onClaimed: @escaping (PolymarketPosition?) -> Void)

    func openPositionDetails(position: PolymarketPosition, onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void)
}
