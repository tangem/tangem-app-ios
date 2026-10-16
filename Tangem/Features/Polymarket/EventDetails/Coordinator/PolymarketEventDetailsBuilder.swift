//
//  PolymarketEventDetailsBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPolymarket

protocol PolymarketEventDetailsBuilder: AnyObject {
    func makeEventDetailsCoordinator(
        eventID: String,
        category: PolymarketCategory?,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onRegionWarning: @escaping () -> Void,
        onClose: @escaping Action<Void>
    ) -> PolymarketEventDetailsCoordinator
}
