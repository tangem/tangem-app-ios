//
//  PolymarketQuoteFailureClock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PolymarketQuoteFailureClock {
    let gracePeriod: TimeInterval

    private var firstFailureDate: Date?

    init(gracePeriod: TimeInterval) {
        self.gracePeriod = gracePeriod
    }

    mutating func shouldSurfaceFailure(hasQuote: Bool, now: Date = Date()) -> Bool {
        let firstFailure = firstFailureDate ?? now
        firstFailureDate = firstFailure

        return now.timeIntervalSince(firstFailure) >= gracePeriod
    }

    mutating func reset() {
        firstFailureDate = nil
    }
}
