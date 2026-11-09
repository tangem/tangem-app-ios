//
//  PolymarketWebSocketBackoffTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemPolymarket

@Suite("Polymarket WebSocket backoff")
struct PolymarketWebSocketBackoffTests {
    @Test("The longest wait doubles with every failed attempt in a row and stops at half a minute", arguments: zip(
        [1, 2, 3, 4, 5, 6, 7, 100],
        [1, 2, 4, 8, 16, 30, 30, 30]
    ))
    func longestWait(attempt: Int, seconds: Int) {
        #expect(PolymarketWebSocketBackoff.delay(forAttempt: attempt, random: { _ in 1 }) == .seconds(seconds))
    }

    @Test("The wait is a random share of the longest wait, so clients dropped together do not come back together")
    func waitIsARandomShare() {
        var askedRange: ClosedRange<Double>?

        let delay = PolymarketWebSocketBackoff.delay(forAttempt: 3) { range in
            askedRange = range
            return 0.25
        }

        #expect(delay == .seconds(1))
        #expect(askedRange == 0 ... 1)
    }
}
