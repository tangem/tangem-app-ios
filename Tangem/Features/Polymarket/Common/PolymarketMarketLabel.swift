//
//  PolymarketMarketLabel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

extension PolymarketMarket {
    var listLabel: String? {
        guard let label = groupItemTitle?.nilIfEmpty else { return nil }

        guard label.range(of: Constants.matchWinner, options: .caseInsensitive) == nil else { return nil }

        return label
    }
}

// MARK: - Constants

private extension PolymarketMarket {
    enum Constants {
        static let matchWinner = "match winner"
    }
}
