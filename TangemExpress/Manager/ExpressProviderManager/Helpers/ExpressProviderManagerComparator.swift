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
    ///
    /// Tiers (from most to least preferred):
    ///   1. eligible — `.permissionRequired`, `.revokeAndPermissionRequired`, `.cexPreview`, `.dexPreview`.
    ///   2. `.restriction(.tooSmallAmount)` — lower minimum (closer to user's amount) wins.
    ///   3. `.restriction(.tooBigAmount)`.
    ///   4. `.idle` / `.error`.
    public static func isBetter(lhs: ExpressAvailableProvider, rhs: ExpressAvailableProvider) -> Bool {
        switch (lhs.getState(), rhs.getState()) {
        // 1) Both `.tooSmallAmount`: lower minimum wins.
        case (.restriction(.tooSmallAmount(let lMinimum, _), _), .restriction(.tooSmallAmount(let rMinimum, _), _)):
            return lMinimum < rMinimum

        // 2) `.tooSmallAmount` beats `.tooBigAmount` / `.idle` / `.error` (and the symmetric inverse).
        case (.restriction(.tooSmallAmount, _), .restriction(.tooBigAmount, _)),
             (.restriction(.tooSmallAmount, _), .idle),
             (.restriction(.tooSmallAmount, _), .error):
            return true

        case (.restriction(.tooBigAmount, _), .restriction(.tooSmallAmount, _)),
             (.idle, .restriction(.tooSmallAmount, _)),
             (.error, .restriction(.tooSmallAmount, _)):
            return false

        // 3) `.tooSmallAmount` loses to eligible (and the symmetric inverse).
        case (.restriction(.tooSmallAmount, _), _):
            return false

        case (_, .restriction(.tooSmallAmount, _)):
            return true

        // 4) `.tooBigAmount` beats `.idle` / `.error` (and the symmetric inverse).
        case (.restriction(.tooBigAmount, _), .idle),
             (.restriction(.tooBigAmount, _), .error):
            return true

        case (.idle, .restriction(.tooBigAmount, _)),
             (.error, .restriction(.tooBigAmount, _)):
            return false

        // 5) Both `.tooBigAmount` — equivalent.
        case (.restriction(.tooBigAmount, _), .restriction(.tooBigAmount, _)):
            return false

        // 6) `.tooBigAmount` loses to eligible (and the symmetric inverse).
        case (.restriction(.tooBigAmount, _), _):
            return false

        case (_, .restriction(.tooBigAmount, _)):
            return true

        // 7) `.idle` / `.error` lose to eligible; equivalent to each other (and the symmetric inverse).
        case (.idle, _), (.error, _):
            return false

        case (_, .idle), (_, .error):
            return true

        // 8) Both eligible (only remaining state combination by elimination).
        //    Callers pre-filter the array by `rateType` (see
        //    `updateIsBestFlag(activeRateType:)` and `currentResult().providers`), so both
        //    sides share the active `rateType` and reading `lhs.rateType` to choose the
        //    fixed/float comparison is safe.
        case (let lState, let rState):
            switch (lState.quote, rState.quote) {
            // `.fixed`: lower `fromAmount` wins (cheapest cost for user).
            case (.some(let lQuote), .some(let rQuote)) where lhs.rateType == .fixed:
                return lQuote.fromAmount < rQuote.fromAmount
            // `.float`: higher `expectAmount` wins (most received).
            case (.some(let lQuote), .some(let rQuote)):
                return lQuote.expectAmount > rQuote.expectAmount
            // Defensive — eligible states always carry a quote.
            default:
                return false
            }
        }
    }
}
