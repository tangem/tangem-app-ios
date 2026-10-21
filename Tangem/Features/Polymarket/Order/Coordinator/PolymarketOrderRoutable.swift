//
//  PolymarketOrderRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol PolymarketOrderRoutable: AnyObject {
    func closeOrder()

    func openMarketClosed()

    func openQuoteUnavailable()

    func openAddFunds()

    func openRegionWarning()

    func openSlippageSelector(percent: Decimal, onConfirm: @escaping (Decimal) -> Void)

    func openSummary(model: PolymarketOrderModel)

    func openFeeBreakdown(model: PolymarketOrderModel)

    func openResult(state: PolymarketOrderResultViewModel.State, content: PolymarketOrderResultViewModel.Content)

    func openLegalTerms(url: URL)

    func openSupport()
}
