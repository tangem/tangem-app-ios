//
//  PolymarketServerClockTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("PolymarketServerClock")
struct PolymarketServerClockTests {
    private let deviceNow = Date(timeIntervalSince1970: 1_787_000_000)

    @Test("Without an answer to go by the device clock is what the caller gets")
    func fallsBackToTheDeviceClock() {
        #expect(makeSUT().now == deviceNow)
    }

    @Test("A device running behind is corrected forward by the difference")
    func correctsADeviceRunningBehind() {
        let clock = makeSUT()

        clock.record(serverDate: deviceNow.addingTimeInterval(1800))

        #expect(clock.now == deviceNow.addingTimeInterval(1800))
    }

    @Test("A device running ahead is corrected back by the difference")
    func correctsADeviceRunningAhead() {
        let clock = makeSUT()

        clock.record(serverDate: deviceNow.addingTimeInterval(-1800))

        #expect(clock.now == deviceNow.addingTimeInterval(-1800))
    }

    @Test("However far the device clock is off, the correction still lands on the backend's time")
    func correctsAClockThatLostYears() {
        let lostYears: TimeInterval = 6 * 365 * 24 * 60 * 60
        let clock = makeSUT()

        clock.record(serverDate: deviceNow.addingTimeInterval(lostYears))

        #expect(clock.now == deviceNow.addingTimeInterval(lostYears))
    }

    @Test("The latest answer replaces the previous correction")
    func latestAnswerWins() {
        let clock = makeSUT()

        clock.record(serverDate: deviceNow.addingTimeInterval(1800))
        clock.record(serverDate: deviceNow.addingTimeInterval(60))

        #expect(clock.now == deviceNow.addingTimeInterval(60))
    }
}

// MARK: - Fixtures

private extension PolymarketServerClockTests {
    func makeSUT() -> PolymarketServerClock {
        let fixedDeviceNow = deviceNow

        return PolymarketServerClock(deviceNow: { fixedDeviceNow })
    }
}
