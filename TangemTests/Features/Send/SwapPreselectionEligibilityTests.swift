//
//  SwapPreselectionEligibilityTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Swap source preselection eligibility")
struct SwapSourcePreselectionEligibilityTests {
    typealias Status = TokenActionAvailabilityProvider.SwapSourceActionAvailabilityStatus

    @Test(
        "A status that can clear once the wallet or Express loads keeps the token as a source",
        arguments: [Status.available, .blockchainLoading, .blockchainUnreachable, .hasOnlyCachedBalance, .expressLoading, .expressUnreachable, .missingAssetRequirement]
    )
    func transientStatusKeepsSource(status: Status) {
        #expect(SwapSourcePreselectionEligibility.canBecomeSource(for: status))
    }

    @Test(
        "A status that refuses the token for good drops it as a source",
        arguments: [Status.jointAccountsComingSoon, .customToken, .yieldModuleApproveNeeded, .cantSignLongTransactions]
    )
    func permanentRefusalDropsSource(status: Status) {
        #expect(!SwapSourcePreselectionEligibility.canBecomeSource(for: status))
    }
}

@Suite("Swap receive preselection eligibility")
struct SwapReceivePreselectionEligibilityTests {
    typealias Status = TokenActionAvailabilityProvider.SwapReceiveActionAvailabilityStatus

    @Test(
        "A status that can clear once the wallet or Express loads keeps the token as a receive side",
        arguments: [Status.available, .expressLoading, .expressUnreachable, .missingAssetRequirement]
    )
    func transientStatusKeepsReceive(status: Status) {
        #expect(SwapReceivePreselectionEligibility.canBecomeReceive(for: status))
    }

    @Test("A custom token is dropped as a receive side")
    func customTokenDropsReceive() {
        #expect(!SwapReceivePreselectionEligibility.canBecomeReceive(for: .customToken))
    }
}
