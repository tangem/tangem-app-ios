//
//  AccountTokenItemsAggregatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemPolymarket
@testable import Tangem

@Suite
struct AccountTokenItemsAggregatorTests {
    @Test("A visible Polymarket account contributes the currency its deposits arrive in")
    func visibleAccountContributesUSDC() {
        let manager = AccountModelsManagerStub(
            accounts: [.polymarket(PolymarketAccountModelStub(state: .active))]
        )

        let tokenItems = AccountTokenItemsAggregator.tokenItems(from: manager)

        #expect(tokenItems == [PolymarketUtilities.usdcTokenItem])
    }

    @Test("An account still syncing keeps contributing, since its deposit screen is reachable")
    func syncNeededAccountContributesUSDC() {
        let manager = AccountModelsManagerStub(
            accounts: [.polymarket(PolymarketAccountModelStub(state: .syncNeeded))]
        )

        let tokenItems = AccountTokenItemsAggregator.tokenItems(from: manager)

        #expect(tokenItems == [PolymarketUtilities.usdcTokenItem])
    }

    @Test("An account the user cannot reach contributes nothing")
    func hiddenAccountContributesNothing() {
        let hiddenStates: [PolymarketAccountState?] = [
            nil,
            .loading,
            .onboarding(.deploying),
            .onboardingFailed(.approving),
            .unavailable,
        ]

        for state in hiddenStates {
            let manager = AccountModelsManagerStub(
                accounts: [.polymarket(PolymarketAccountModelStub(state: state))]
            )

            let tokenItems = AccountTokenItemsAggregator.tokenItems(from: manager)

            #expect(tokenItems.isEmpty, "State \(String(describing: state)) must not contribute currencies")
        }
    }
}
