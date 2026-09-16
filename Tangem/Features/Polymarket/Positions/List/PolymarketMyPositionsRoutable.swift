//
//  PolymarketMyPositionsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketMyPositionsRoutable: AnyObject {
    func closeMyPositions()

    @MainActor
    func openHowItWorks()

    func openPositionDetails(position: PolymarketPosition, onOrderPlaced: @escaping @MainActor (Task<Void, Never>?) -> Void)
}
