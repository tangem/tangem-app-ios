//
//  TotalTokenBalanceComposition.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The total as it stands while the compositors fold their sources into it.
struct TotalTokenBalanceComposition {
    let base: TokenBalanceType

    private(set) var balance: Decimal
    private(set) var cacheDates: [Date] = []
    private(set) var isLoading: Bool

    init(base: TokenBalanceType, balance: Decimal) {
        self.base = base
        self.balance = balance
        isLoading = base.isLoading
    }

    /// Folds one source in the way nearly every source wants: its loading state and cache date are tracked.
    /// A source with no amount to give — failed while the base is healthy, or loading without a cache — still
    /// counts towards the loading state, but leaves the balance and the cache dates alone.
    func folding(_ state: TokenBalanceType, combine: (_ total: Decimal, _ value: Decimal) -> Decimal) -> Self {
        var composition = self
        composition.isLoading = isLoading || state.isLoading

        guard let value = contribution(of: state) else {
            return composition
        }

        composition.balance = combine(balance, value)

        if let cacheDate = state.cached?.date {
            composition.cacheDates.append(cacheDate)
        }

        return composition
    }

    /// A failed source's stale cache counts only once the base failed too
    private func contribution(of state: TokenBalanceType) -> Decimal? {
        if state.isFailure, !base.isFailure {
            return nil
        }

        return state.value
    }
}
