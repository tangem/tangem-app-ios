//
//  PolymarketQuoteFailureClockTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Polymarket quote failure clock")
struct PolymarketQuoteFailureClockTests {
    private let start = Date(timeIntervalSince1970: 1_787_300_000)

    @Test("A first failure with nothing on screen is retried quietly before it is shown")
    func failureWithoutAQuoteWaitsToo() {
        let clock = FailureClock(gracePeriod: 30)

        #expect(!clock.surfaces(hasQuote: false, at: start))
        #expect(clock.surfaces(hasQuote: false, at: start.addingTimeInterval(30)))
    }

    @Test("A quote already on screen buys the network the grace period")
    func failureWithAQuoteWaits() {
        let clock = FailureClock(gracePeriod: 30)

        #expect(!clock.surfaces(at: start))
        #expect(!clock.surfaces(at: start.addingTimeInterval(29)))
    }

    @Test("Once the grace period runs out the failure is shown")
    func failureSurfacesAfterTheGracePeriod() {
        let clock = FailureClock(gracePeriod: 30)

        #expect(!clock.surfaces(at: start))
        #expect(clock.surfaces(at: start.addingTimeInterval(30)))
    }

    @Test("The grace period is counted from the first failure, not the last one")
    func gracePeriodRunsFromTheFirstFailure() {
        let clock = FailureClock(gracePeriod: 30)

        #expect(!clock.surfaces(at: start))
        #expect(!clock.surfaces(at: start.addingTimeInterval(10)))
        #expect(!clock.surfaces(at: start.addingTimeInterval(20)))
        #expect(clock.surfaces(at: start.addingTimeInterval(31)))
    }

    @Test("A quote that got through starts the count over")
    func aSuccessfulQuoteStartsTheCountOver() {
        let clock = FailureClock(gracePeriod: 30)

        #expect(!clock.surfaces(at: start))

        clock.reset()

        #expect(!clock.surfaces(at: start.addingTimeInterval(100)))
        #expect(clock.surfaces(at: start.addingTimeInterval(130)))
    }

    @Test("A failure the screen never saw does not spend the next visit's grace period")
    func leavingTheScreenStartsTheCountOver() {
        let clock = FailureClock(gracePeriod: 30)

        #expect(!clock.surfaces(at: start))

        clock.reset()

        #expect(!clock.surfaces(at: start.addingTimeInterval(3600)))
    }
}

// MARK: - Fixtures

private final class FailureClock {
    private var clock: PolymarketQuoteFailureClock

    init(gracePeriod: TimeInterval) {
        clock = PolymarketQuoteFailureClock(gracePeriod: gracePeriod)
    }

    func surfaces(hasQuote: Bool = true, at date: Date) -> Bool {
        clock.shouldSurfaceFailure(hasQuote: hasQuote, now: date)
    }

    func reset() {
        clock.reset()
    }
}
