//
//  ScaledUIAmountTests.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

struct ScaledUIAmountTests {
    @Test
    func absentMultiplierLeavesAmountUntouched() throws {
        #expect(try ScaledUIAmount.unscale(displayed: 1000, by: nil) == 1000)
        #expect(ScaledUIAmount.scale(onChain: 1000, by: nil) == 1000)
    }

    @Test
    func neutralMultiplierLeavesAmountUntouched() throws {
        #expect(try ScaledUIAmount.unscale(displayed: 1000, by: 1) == 1000)
        #expect(ScaledUIAmount.scale(onChain: 1000, by: 1) == 1000)
    }

    @Test
    func displayedAmountIsDividedByMultiplier() throws {
        #expect(try ScaledUIAmount.unscale(displayed: 1000, by: 10) == 100)
        #expect(try ScaledUIAmount.unscale(displayed: 1000, by: 0.5) == 2000)
    }

    @Test
    func onChainAmountIsMultipliedBack() {
        #expect(ScaledUIAmount.scale(onChain: 100, by: 10) == 1000)
        #expect(ScaledUIAmount.scale(onChain: 2000, by: 0.5) == 1000)
    }

    @Test
    func conversionsRoundTrip() throws {
        let displayed = Decimal(string: "1234.56789")!
        let multiplier = Decimal(string: "7.5")!

        let onChain = try ScaledUIAmount.unscale(displayed: displayed, by: multiplier)

        #expect(ScaledUIAmount.scale(onChain: onChain, by: multiplier) == displayed)
    }

    @Test(arguments: [Decimal.zero, Decimal(-1)])
    func nonPositiveMultiplierIsRejected(multiplier: Decimal) {
        #expect(throws: BlockchainSdkError.self) {
            try ScaledUIAmount.unscale(displayed: 1000, by: multiplier)
        }
    }
}
