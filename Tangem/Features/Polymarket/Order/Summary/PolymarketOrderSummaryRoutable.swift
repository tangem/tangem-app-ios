//
//  PolymarketOrderSummaryRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol PolymarketOrderSummaryRoutable: AnyObject {
    func closeSummary()
    func closeOrder()
    func openLegalTerms(url: URL)

    @MainActor
    func openFeeBreakdown(model: PolymarketOrderModel)

    func openResult()
}
