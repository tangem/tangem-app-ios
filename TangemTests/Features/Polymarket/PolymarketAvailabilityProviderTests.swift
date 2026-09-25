//
//  PolymarketAvailabilityProviderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Polymarket availability")
struct PolymarketAvailabilityProviderTests {
    @Test("A wallet that already has an account keeps the feature")
    func walletWithAnAccountKeepsTheFeature() {
        let sut = CommonPolymarketAvailabilityProvider()

        #expect(sut.isAvailable(hasAccount: { true }))
    }

    @Test("A wallet without an account follows the feature-wide decision")
    func walletWithoutAnAccountFollowsTheFeature() {
        let sut = CommonPolymarketAvailabilityProvider()

        #expect(sut.isAvailable(hasAccount: { false }) == sut.isAvailable)
    }

    @Test("An existing account does not open the feature for the wallets that have none")
    func anExistingAccountDoesNotOpenTheFeatureForEveryone() {
        let sut = CommonPolymarketAvailabilityProvider()
        let featureWideAvailability = sut.isAvailable

        _ = sut.isAvailable(hasAccount: { true })

        #expect(sut.isAvailable == featureWideAvailability)
    }
}
