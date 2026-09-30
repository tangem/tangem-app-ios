//
//  PolymarketOrderRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol PolymarketOrderRoutable: AnyObject {
    func closeOrder()

    @MainActor
    func openMarketClosed()

    @MainActor
    func openQuoteUnavailable()

    func openAddFunds()

    func openSlippageSelector(percent: Decimal, onConfirm: @escaping (Decimal) -> Void)

    @MainActor
    func openSummary(model: PolymarketOrderModel)
}
