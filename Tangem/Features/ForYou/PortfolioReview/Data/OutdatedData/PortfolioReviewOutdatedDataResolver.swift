//
//  PortfolioReviewOutdatedDataResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PortfolioReviewOutdatedDataResolver {
    /// The "Some token balances could not be updated" show condition: a displayed token failed to refresh
    /// AND the donut actually drew — the banner marks rendered-but-incomplete data, so a "can't load" card
    /// never carries it. Cache presence is irrelevant: a single valueless token nulls the combined cache
    /// while the chart still renders from whatever the displayed holdings carry.
    static func isOutdated(
        _ totalBalance: TotalBalanceState,
        displayedItems: Set<TokenItem>,
        chart: PortfolioReviewViewModel.ViewState.Chart?
    ) -> Bool {
        guard case .loaded = chart else { return false }

        switch totalBalance {
        case .failed(_, let failedItems):
            return failedItems.contains { displayedItems.contains($0) }
        case .empty, .loading, .loaded:
            return false
        }
    }
}
