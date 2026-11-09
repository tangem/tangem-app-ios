//
//  PolymarketEventPlaceholder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPolymarket

struct PolymarketEventPlaceholder {
    let title: String
    let marketsCount: Int?
}

extension PolymarketEventPlaceholder {
    init(event: PolymarketEvent) {
        self.init(title: event.title, marketsCount: event.totalMarketsCount)
    }

    static func legendLineCount(marketsCount: Int?) -> Int {
        guard let marketsCount else { return Constants.multipleMarketsLegendLines }

        return marketsCount > 1 ? Constants.multipleMarketsLegendLines : Constants.singleMarketLegendLines
    }
}

// MARK: - Constants

private extension PolymarketEventPlaceholder {
    enum Constants {
        static let singleMarketLegendLines = 1
        static let multipleMarketsLegendLines = 2
    }
}
