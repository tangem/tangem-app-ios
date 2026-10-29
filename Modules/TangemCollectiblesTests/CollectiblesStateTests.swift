//
//  CollectiblesStateTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemCollectibles

@Suite("CollectiblesState")
struct CollectiblesStateTests {
    @Test("Only a vault confirmed on chain is visible", arguments: Self.visibilityArguments)
    func accountVisibility(state: CollectiblesState, isVisible: Bool) {
        #expect(state.isAccountVisible == isVisible)
    }

    @Test(
        "A vault naming another session key needs a relink, and so does a recorded account with no key on this phone",
        arguments: Self.relinkArguments
    )
    func relinkRequirement(state: CollectiblesState, isRecorded: Bool, isRelinkRequired: Bool) {
        #expect(state.isRelinkRequired(isRecorded: isRecorded) == isRelinkRequired)
    }

    @Test("Only a recorded account with no key on this phone needs a sync", arguments: Self.syncArguments)
    func syncRequirement(state: CollectiblesState, isRecorded: Bool, isSyncRequired: Bool) {
        #expect(state.isSyncRequired(isRecorded: isRecorded) == isSyncRequired)
    }
}

// MARK: - Arguments

extension CollectiblesStateTests {
    static let visibilityArguments: [(state: CollectiblesState, isVisible: Bool)] = [
        (state: .ready(Constants.vaultInfo), isVisible: true),
        (state: .rekeyRequired(Constants.vaultInfo), isVisible: true),
        (state: .unresolved, isVisible: false),
        (state: .notOnboarded, isVisible: false),
        (state: .coldOwnerNotDerived, isVisible: false),
    ]

    static let relinkArguments: [(state: CollectiblesState, isRecorded: Bool, isRelinkRequired: Bool)] = [
        (state: .ready(Constants.vaultInfo), isRecorded: true, isRelinkRequired: false),
        (state: .rekeyRequired(Constants.vaultInfo), isRecorded: false, isRelinkRequired: true),
        (state: .unresolved, isRecorded: true, isRelinkRequired: false),
        (state: .notOnboarded, isRecorded: true, isRelinkRequired: false),
        (state: .coldOwnerNotDerived, isRecorded: true, isRelinkRequired: true),
        (state: .coldOwnerNotDerived, isRecorded: false, isRelinkRequired: false),
    ]

    static let syncArguments: [(state: CollectiblesState, isRecorded: Bool, isSyncRequired: Bool)] = [
        (state: .ready(Constants.vaultInfo), isRecorded: true, isSyncRequired: false),
        (state: .rekeyRequired(Constants.vaultInfo), isRecorded: true, isSyncRequired: false),
        (state: .unresolved, isRecorded: true, isSyncRequired: false),
        (state: .notOnboarded, isRecorded: true, isSyncRequired: false),
        (state: .coldOwnerNotDerived, isRecorded: true, isSyncRequired: true),
        (state: .coldOwnerNotDerived, isRecorded: false, isSyncRequired: false),
    ]
}

// MARK: - Helpers

private extension CollectiblesStateTests {
    enum Constants {
        static let vaultInfo = CollectiblesVaultInfo(
            vaultAddress: "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA",
            sessionKey: Data(repeating: 0xBB, count: 32),
            perSpinCap: 1,
            dailyCap: 1,
            spentToday: 0,
            dayIndex: 0
        )
    }
}
