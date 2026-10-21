//
//  PolymarketOrderSummaryRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

@MainActor
protocol PolymarketOrderSummaryRoutable: AnyObject {
    func closeSummary()
    func closeOrder()
    func openLegalTerms(url: URL)
    func openSupport()

    func openFeeBreakdown(model: PolymarketOrderModel)

    func openResult(state: PolymarketOrderResultViewModel.State, content: PolymarketOrderResultViewModel.Content)
}
