//
//  SwapIgnoringExpressEligibilityTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Swap source eligibility ignoring Express")
struct SwapSourceIgnoringExpressEligibilityTests {
    typealias Status = TokenActionAvailabilityProvider.SwapSourceActionAvailabilityStatus

    @Test(
        "An available token or one that only waits for Express can be the source",
        arguments: [Status.available, .expressLoading, .expressUnreachable]
    )
    func expressStatusesDoNotBlockSource(status: Status) {
        #expect(SwapSourceIgnoringExpressEligibility.canBecomeSource(for: status))
    }

    @Test(
        "Any other reason keeps the token from being the source",
        arguments: [Status.jointAccountsComingSoon, .customToken, .blockchainLoading, .blockchainUnreachable, .hasOnlyCachedBalance, .cantSignLongTransactions, .missingAssetRequirement, .yieldModuleApproveNeeded]
    )
    func otherStatusesBlockSource(status: Status) {
        #expect(!SwapSourceIgnoringExpressEligibility.canBecomeSource(for: status))
    }
}

@Suite("Swap receive eligibility ignoring Express")
struct SwapReceiveIgnoringExpressEligibilityTests {
    typealias Status = TokenActionAvailabilityProvider.SwapReceiveActionAvailabilityStatus

    @Test(
        "An available token or one that only waits for Express can be the receive side",
        arguments: [Status.available, .expressLoading, .expressUnreachable]
    )
    func expressStatusesDoNotBlockReceive(status: Status) {
        #expect(SwapReceiveIgnoringExpressEligibility.canBecomeReceive(for: status))
    }

    @Test(
        "A custom token or a missing asset requirement keeps the token from being the receive side",
        arguments: [Status.customToken, .missingAssetRequirement]
    )
    func otherStatusesBlockReceive(status: Status) {
        #expect(!SwapReceiveIgnoringExpressEligibility.canBecomeReceive(for: status))
    }
}
