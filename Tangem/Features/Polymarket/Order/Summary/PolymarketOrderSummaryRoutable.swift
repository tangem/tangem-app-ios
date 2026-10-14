//
//  PolymarketOrderSummaryRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketOrderSummaryRoutable: AnyObject {
    func closeSummary()
    func returnToMain()
    func openLegalTerms(url: URL)
    func openSupport()

    @MainActor
    func openFeeBreakdown(model: PolymarketOrderModel)

    @MainActor
    func openResult(state: PolymarketOrderResultViewModel.State, content: PolymarketOrderResultViewModel.Content)
}
