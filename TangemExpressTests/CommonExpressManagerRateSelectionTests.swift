//
//  CommonExpressManagerRateSelectionTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemExpress

@Suite("CommonExpressManager rate selection — rate follows the requested (edited-field) rate; [REDACTED_INFO]")
struct CommonExpressManagerRateSelectionTests {
    @Test("Float request is honored when float providers exist")
    func floatRequestHonored() {
        let rate = CommonExpressManager.preferredRate(hasFloatProviders: true, requested: .float)

        #expect(rate == .float)
    }

    @Test("Fixed request is honored regardless of float availability", arguments: [true, false])
    func fixedRequestHonored(hasFloatProviders: Bool) {
        let rate = CommonExpressManager.preferredRate(hasFloatProviders: hasFloatProviders, requested: .fixed)

        #expect(rate == .fixed)
    }

    @Test("Float request falls back to fixed when there are no float providers")
    func floatRequestFallsBackToFixedWhenNoFloatProviders() {
        let rate = CommonExpressManager.preferredRate(hasFloatProviders: false, requested: .float)

        #expect(rate == .fixed)
    }
}
