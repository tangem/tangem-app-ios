//
//  JointAccountStateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

@Suite("Tests for the state a joint account is asked for by")
struct JointAccountStateTests {
    @Test(
        "An account is still being put together until every slot is taken and the creator has activated it",
        arguments: [
            (JointAccountStatus.pending, true),
            (.confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"), true),
            (.active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"), false),
            (.cancelled, false),
        ]
    )
    func pendingFollowsTheStatus(status: JointAccountStatus, isPending: Bool) {
        #expect(JointAccountModelsSelector.JointAccountState.pending.isMatching(status: status) == isPending)
    }

    @Test(
        "An account works only once it is activated",
        arguments: [
            (JointAccountStatus.active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"), true),
            (.pending, false),
            (.confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"), false),
            (.cancelled, false),
        ]
    )
    func activeFollowsTheStatus(status: JointAccountStatus, isActive: Bool) {
        #expect(JointAccountModelsSelector.JointAccountState.active.isMatching(status: status) == isActive)
    }

    @Test(
        "An account asked for without a state named is taken whatever has become of it",
        arguments: [
            JointAccountStatus.pending,
            .confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"),
            .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"),
            .cancelled,
            .unknown,
        ]
    )
    func allTakesEveryStatus(status: JointAccountStatus) {
        #expect(JointAccountModelsSelector.JointAccountState.all.isMatching(status: status))
    }

    @Test("A status this version has never heard of answers to neither named state, so only `all` keeps the account")
    func unfamiliarStatusMatchesNeitherNamedState() {
        #expect(!JointAccountModelsSelector.JointAccountState.pending.isMatching(status: .unknown))
        #expect(!JointAccountModelsSelector.JointAccountState.active.isMatching(status: .unknown))
        #expect(JointAccountModelsSelector.JointAccountState.all.isMatching(status: .unknown))
    }
}
