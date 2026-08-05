//
//  PortfolioReviewIndicatorsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol PortfolioReviewIndicatorsProvider {
    /// Coin-indicator readings for many symbols in one batch, keyed by uppercased symbol.
    func loadIndicators(symbols: [String]) async throws -> [String: [TokenSummaryIndicator]]
}
