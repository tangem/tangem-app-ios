//
//  ExpressProviderManagerComparator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressProviderManagerComparator {
    /// `.min(by:)` / `.sorted(by:)` returns the best provider first.
    /// Callers must pre-filter the array to providers whose `supportedRateTypes`
    /// contain the active `rateType` (e.g. via `filteredByRateType`).
    public static func isBetter(
        _ lhs: ExpressAvailableProvider,
        _ rhs: ExpressAvailableProvider,
        rateType: ExpressProviderRateType
    ) -> Bool {
        switch (lhs.getState(), rhs.getState()) {
        case (.restriction(.tooSmallAmount(let lMinimum, _), _), .restriction(.tooSmallAmount(let rMinimum, _), _)):
            return lMinimum < rMinimum

        case (.restriction(.tooSmallAmount, _), .restriction(.tooBigAmount, _)),
             (.restriction(.tooSmallAmount, _), .idle),
             (.restriction(.tooSmallAmount, _), .error):
            return true

        case (.restriction(.tooBigAmount, _), .restriction(.tooSmallAmount, _)),
             (.idle, .restriction(.tooSmallAmount, _)),
             (.error, .restriction(.tooSmallAmount, _)):
            return false

        case (.restriction(.tooSmallAmount, _), _):
            return false

        case (_, .restriction(.tooSmallAmount, _)):
            return true

        case (.restriction(.tooBigAmount, _), .idle),
             (.restriction(.tooBigAmount, _), .error):
            return true

        case (.idle, .restriction(.tooBigAmount, _)),
             (.error, .restriction(.tooBigAmount, _)):
            return false

        case (.restriction(.tooBigAmount, _), .restriction(.tooBigAmount, _)):
            return false

        case (.restriction(.tooBigAmount, _), _):
            return false

        case (_, .restriction(.tooBigAmount, _)):
            return true

        case (.idle, _), (.error, _):
            return false

        case (_, .idle), (_, .error):
            return true

        case (let lState, let rState):
            switch (lState.quote, rState.quote) {
            case (.some(let lQuote), .some(let rQuote)) where rateType == .fixed:
                return lQuote.fromAmount < rQuote.fromAmount
            case (.some(let lQuote), .some(let rQuote)):
                return lQuote.expectAmount > rQuote.expectAmount
            case (.some, .none):
                return true
            case (.none, .some), (.none, .none):
                return false
            }
        }
    }
}
