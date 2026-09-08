//
//  PolymarketAccountStateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Polymarket account row visibility")
struct PolymarketAccountStateTests {
    @Test(
        "An account that exists reaches the wallet screen, whether or not this device can trade with it",
        arguments: [PolymarketAccountState.active, .syncNeeded]
    )
    func existingAccountsAreShown(state: PolymarketAccountState) {
        #expect(state.isAccountVisible)
    }

    @Test(
        "Everything unfinished, broken or still loading stays off the wallet screen",
        arguments: [
            PolymarketAccountState.loading,
            .onboarding(.deploying),
            .onboarding(.deployed),
            .onboarding(.approving),
            .onboardingFailed(.deploying),
            .onboardingFailed(.approving),
            .unavailable,
        ]
    )
    func everythingElseIsHidden(state: PolymarketAccountState) {
        #expect(!state.isAccountVisible)
    }
}
