//
//  PolymarketOrderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

final class PolymarketOrderViewModel: ObservableObject {
    let market: PolymarketMarket
    let outcome: PolymarketOutcome

    private weak var coordinator: PolymarketOrderRoutable?

    init(market: PolymarketMarket, outcome: PolymarketOutcome, coordinator: PolymarketOrderRoutable?) {
        self.market = market
        self.outcome = outcome
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeOrder()
    }
}
