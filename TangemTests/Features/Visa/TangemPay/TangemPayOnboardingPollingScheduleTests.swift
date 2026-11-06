//
//  TangemPayOnboardingPollingScheduleTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Onboarding polling schedule")
struct TangemPayOnboardingPollingScheduleTests {
    typealias Schedule = TangemPayOnboardingPollingService.Schedule

    @Test("The first two minutes poll every ten seconds", arguments: [0.0, 10, 60, 119])
    func fastPhasePollsEveryTenSeconds(elapsed: Double) {
        #expect(Schedule.nextInterval(afterElapsed: elapsed) == 10)
    }

    @Test("After two minutes polling slows down to once a minute", arguments: [120.0, 180, 600, 839])
    func slowPhasePollsEveryMinute(elapsed: Double) {
        #expect(Schedule.nextInterval(afterElapsed: elapsed) == 60)
    }

    @Test("Polling stops once the next tick would pass fifteen minutes", arguments: [841.0, 900, 1800])
    func stopsAfterFifteenMinutes(elapsed: Double) {
        #expect(Schedule.nextInterval(afterElapsed: elapsed) == nil)
    }
}
