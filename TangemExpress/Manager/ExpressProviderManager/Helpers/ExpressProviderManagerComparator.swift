//
//  ExpressProviderManagerComparator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressProviderManagerComparator {
    /// Tiers (from most to least preferred):
    ///   1. Eligible — `.permissionRequired`, `.revokeAndPermissionRequired`, `.cexPreview`, `.dexPreview`.
    ///   2. `.restriction(.tooSmallAmount)` — lower minimum (closer to user's amount) wins.
    ///   3. `.restriction(.tooBigAmount)`.
    ///   4. `.idle` / `.error` / `.restriction(.regionRestricted)`.
    ///
    /// `.regionRestricted` sits in the last tier rather than with the amount restrictions: the user can
    /// reach an amount restriction by typing a different amount, but nothing they do lifts a regional one.
    public static func isBetter(lhs: ExpressAvailableProvider, rhs: ExpressAvailableProvider) -> Bool {
        assert(lhs.rateType == rhs.rateType, "Comparator requires both providers to share the same `rateType`")

        switch (lhs.getState(), rhs.getState()) {
        case (.restriction(.tooSmallAmount(let lMinimum, _), _), .restriction(.tooSmallAmount(let rMinimum, _), _)):
            return lMinimum < rMinimum

        case (.restriction(.tooSmallAmount, _), .restriction(.tooBigAmount, _)),
             (.restriction(.tooSmallAmount, _), .idle),
             (.restriction(.tooSmallAmount, _), .error),
             (.restriction(.tooSmallAmount, _), .restriction(.regionRestricted, _)):
            return true

        case (.restriction(.tooBigAmount, _), .restriction(.tooSmallAmount, _)),
             (.idle, .restriction(.tooSmallAmount, _)),
             (.error, .restriction(.tooSmallAmount, _)),
             (.restriction(.regionRestricted, _), .restriction(.tooSmallAmount, _)):
            return false

        case (.restriction(.tooSmallAmount, _), _):
            return false

        case (_, .restriction(.tooSmallAmount, _)):
            return true

        case (.restriction(.tooBigAmount, _), .idle),
             (.restriction(.tooBigAmount, _), .error),
             (.restriction(.tooBigAmount, _), .restriction(.regionRestricted, _)):
            return true

        case (.idle, .restriction(.tooBigAmount, _)),
             (.error, .restriction(.tooBigAmount, _)),
             (.restriction(.regionRestricted, _), .restriction(.tooBigAmount, _)):
            return false

        case (.restriction(.tooBigAmount, _), .restriction(.tooBigAmount, _)):
            return false

        case (.restriction(.tooBigAmount, _), _):
            return false

        case (_, .restriction(.tooBigAmount, _)):
            return true

        case (.idle, _), (.error, _), (.restriction(.regionRestricted, _), _):
            return false

        case (_, .idle), (_, .error), (_, .restriction(.regionRestricted, _)):
            return true

        case (let lState, let rState):
            switch (lState.quote, rState.quote) {
            case (.some(let lQuote), .some(let rQuote)) where lhs.rateType == .fixed && rhs.rateType == .fixed:
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
