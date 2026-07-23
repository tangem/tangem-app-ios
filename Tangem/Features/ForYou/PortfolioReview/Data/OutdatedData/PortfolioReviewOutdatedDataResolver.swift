//
//  PortfolioReviewOutdatedDataResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PortfolioReviewOutdatedDataResolver {
    /// The main screen's "Some token balances could not be updated" show condition, scoped to the displayed tokens.
    static func isOutdated(_ totalBalance: TotalBalanceState, displayedItems: Set<TokenItem>) -> Bool {
        switch totalBalance {
        case .failed(cached: .some, let failedItems):
            return failedItems.contains { displayedItems.contains($0) }
        case .failed(cached: .none, _), .empty, .loading, .loaded:
            return false
        }
    }
}
