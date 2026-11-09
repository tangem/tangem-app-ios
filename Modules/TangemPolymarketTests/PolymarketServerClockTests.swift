//
//  PolymarketServerClockTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemPolymarket

@Suite("PolymarketServerClock", .timeLimit(.minutes(1)))
struct PolymarketServerClockTests {
    private let deviceStart = Date(timeIntervalSince1970: 1_787_000_000)

    @Test("Without an answer to go by the device clock is what the caller gets")
    func fallsBackToTheDeviceClock() {
        let deviceClock = makeDeviceClock()
        let clock = makeSUT(deviceClock: deviceClock)

        #expect(clock.now == deviceStart)

        deviceClock.withLock { $0 += 600 }

        #expect(clock.now == deviceStart.addingTimeInterval(600))
    }

    @Test(
        "The correction keeps the backend's time as the device clock moves on, whichever way the device is off",
        arguments: [1800, -1800, 31_536_000, -7] as [TimeInterval]
    )
    func correctionFollowsTheDeviceClock(serverOffset: TimeInterval) {
        let deviceClock = makeDeviceClock()
        let clock = makeSUT(deviceClock: deviceClock)
        let serverDate = deviceStart.addingTimeInterval(serverOffset)

        clock.record(serverDate: serverDate)
        deviceClock.withLock { $0 += 600 }

        #expect(clock.now == serverDate.addingTimeInterval(600))
    }

    @Test("The latest answer replaces the previous correction")
    func latestAnswerWins() {
        let deviceClock = makeDeviceClock()
        let clock = makeSUT(deviceClock: deviceClock)

        clock.record(serverDate: deviceStart.addingTimeInterval(1800))
        clock.record(serverDate: deviceStart.addingTimeInterval(60))

        #expect(clock.now == deviceStart.addingTimeInterval(60))
    }
}

// MARK: - Fixtures

private extension PolymarketServerClockTests {
    func makeDeviceClock() -> OSAllocatedUnfairLock<Date> {
        OSAllocatedUnfairLock(initialState: deviceStart)
    }

    func makeSUT(deviceClock: OSAllocatedUnfairLock<Date>) -> PolymarketServerClock {
        PolymarketServerClock(deviceNow: { deviceClock.withLock { $0 } })
    }
}
