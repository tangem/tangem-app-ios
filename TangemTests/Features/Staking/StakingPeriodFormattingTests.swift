//
//  StakingPeriodFormattingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemStaking
@testable import Tangem

@Suite("Staking Period formatting")
struct StakingPeriodFormattingTests {
    @Test("A whole-hour seconds period renders in hours, not truncated to days")
    func secondsRenderInHours() {
        #expect(
            Period.seconds(129600).formatted(formatter: makeFormatter())
                == DateComponentsFormatter.seconds.string(from: DateComponents(hour: 36))
        )
    }

    @Test("A sub-hour period renders in minutes, not zero hours")
    func subHourRendersInMinutes() {
        #expect(
            Period.seconds(2400).formatted(formatter: makeFormatter())
                == DateComponentsFormatter.seconds.string(from: DateComponents(minute: 40))
        )
    }

    @Test("A mixed period keeps both hours and minutes")
    func mixedKeepsHoursAndMinutes() {
        #expect(
            Period.seconds(45000).formatted(formatter: makeFormatter())
                == DateComponentsFormatter.seconds.string(from: DateComponents(hour: 12, minute: 30))
        )
    }

    @Test("A days period still renders through the day formatter")
    func daysStillRenderAsDays() {
        let formatter = makeFormatter()

        #expect(Period.days(7).formatted(formatter: formatter) == formatter.string(from: DateComponents(day: 7)))
    }
}

// MARK: - Private helpers

private extension StakingPeriodFormattingTests {
    func makeFormatter() -> DateComponentsFormatter {
        DateComponentsFormatter.staking()
    }
}
