//
//  PolymarketUSDAmount.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

struct PolymarketUSDAmount {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    private let usd: Decimal?
    private let tokenItem: TokenItem

    init(usd: Decimal?, tokenItem: TokenItem = PolymarketUtilities.usdcTokenItem) {
        self.usd = usd
        self.tokenItem = tokenItem
    }

    func inToken() -> Decimal? {
        guard let usd else {
            return nil
        }

        guard let priceUsd = quotesRepository.quote(for: tokenItem)?.priceUsd, priceUsd > 0 else {
            return usd
        }

        return (usd / priceUsd).rounded(scale: tokenItem.decimalCount, roundingMode: .up)
    }
}
