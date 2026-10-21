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
