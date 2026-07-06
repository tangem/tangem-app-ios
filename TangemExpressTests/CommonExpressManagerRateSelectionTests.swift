//
//  CommonExpressManagerRateSelectionTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemExpress

@Suite("CommonExpressManager rate selection — [REDACTED_INFO] fixed-rate preference for send-via-swap")
struct CommonExpressManagerRateSelectionTests {
    // MARK: - Send-via-swap prefers fixed

    @Test("Source amount entered before send-via-swap quotes fixed when the pair has fixed providers")
    func swapAndSendPrefersFixedOverFloat() {
        let rate = CommonExpressManager.preferredRate(
            operationType: .swapAndSend,
            hasFixedProviders: true,
            hasFloatProviders: true,
            requested: .float
        )

        #expect(rate == .fixed)
    }

    @Test("Send-via-swap keeps fixed when a receive amount already requests it")
    func swapAndSendKeepsFixed() {
        let rate = CommonExpressManager.preferredRate(
            operationType: .swapAndSend,
            hasFixedProviders: true,
            hasFloatProviders: true,
            requested: .fixed
        )

        #expect(rate == .fixed)
    }

    @Test("Send-via-swap falls back to float when the pair has no fixed providers")
    func swapAndSendWithoutFixedUsesFloat() {
        let rate = CommonExpressManager.preferredRate(
            operationType: .swapAndSend,
            hasFixedProviders: false,
            hasFloatProviders: true,
            requested: .float
        )

        #expect(rate == .float)
    }

    // MARK: - Other flows are untouched

    @Test(
        "Regular swap and onramp keep the direction-implied float rate even when fixed providers exist",
        arguments: [ExpressOperationType.swap, .onramp]
    )
    func nonSendFlowsKeepFloat(operationType: ExpressOperationType) {
        let rate = CommonExpressManager.preferredRate(
            operationType: operationType,
            hasFixedProviders: true,
            hasFloatProviders: true,
            requested: .float
        )

        #expect(rate == .float)
    }

    // MARK: - Legacy float-empty fallback

    @Test(
        "Float request falls back to fixed when no float providers exist, for any non-send-via-swap flow",
        arguments: [ExpressOperationType.swap, .onramp]
    )
    func floatRequestFallsBackToFixedWhenNoFloatProviders(operationType: ExpressOperationType) {
        let rate = CommonExpressManager.preferredRate(
            operationType: operationType,
            hasFixedProviders: true,
            hasFloatProviders: false,
            requested: .float
        )

        #expect(rate == .fixed)
    }

    @Test(
        "Fixed request is honored regardless of flow",
        arguments: [ExpressOperationType.swap, .onramp, .swapAndSend]
    )
    func fixedRequestHonored(operationType: ExpressOperationType) {
        let rate = CommonExpressManager.preferredRate(
            operationType: operationType,
            hasFixedProviders: true,
            hasFloatProviders: true,
            requested: .fixed
        )

        #expect(rate == .fixed)
    }

    @Test("Send-via-swap honors a fixed receive request even when no float providers exist")
    func swapAndSendFixedRequestWithoutFloatProviders() {
        let rate = CommonExpressManager.preferredRate(
            operationType: .swapAndSend,
            hasFixedProviders: true,
            hasFloatProviders: false,
            requested: .fixed
        )

        #expect(rate == .fixed)
    }
}
