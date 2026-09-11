//
//  StakeKitPeriodMappingTests.swift
//  TangemStakingTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemStaking

@Suite("StakeKit Period mapping")
struct StakeKitPeriodMappingTests {
    typealias SUT = StakeKitMapper

    @Test("A period carrying seconds maps to .seconds")
    func periodWithSecondsMapsToSeconds() throws {
        let period = try decodePeriod(#"{"days": 1, "seconds": 129600}"#)

        #expect(period.seconds == 129600)
        #expect(SUT().mapToPeriod(from: period) == .seconds(129600))
    }

    @Test(
        "A period without a usable seconds falls back to .days",
        arguments: [#"{"days": 21}"#, #"{"days": 21, "seconds": null}"#]
    )
    func periodWithoutSecondsMapsToDays(json: String) throws {
        let period = try decodePeriod(json)

        #expect(period.seconds == nil)
        #expect(SUT().mapToPeriod(from: period) == .days(21))
    }
}

// MARK: - Private helpers

private extension StakeKitPeriodMappingTests {
    typealias Period = StakeKitDTO.Yield.Info.Response.Metadata.Period

    func decodePeriod(_ json: String) throws -> Period {
        try JSONDecoder().decode(Period.self, from: Data(json.utf8))
    }
}
