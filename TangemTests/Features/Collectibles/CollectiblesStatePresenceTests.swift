//
//  CollectiblesStatePresenceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemCollectibles
@testable import Tangem

@Suite("CollectiblesState presence")
struct CollectiblesStatePresenceTests {
    typealias SUT = CollectiblesState

    // MARK: - Answering

    @Test(
        "A confirmed vault answers yes, whatever the mark says",
        arguments: [SUT.ready(.stub), .rekeyRequired(.stub)], [true, false]
    )
    func confirmedVaultAnswersYes(state: SUT, isMarkedLocally: Bool) {
        #expect(state.hasAccount(markedLocally: isMarkedLocally))
    }

    @Test(
        "A vault that is missing, and one with no address to read at, answer no even when marked",
        arguments: [SUT.notOnboarded, .coldOwnerNotDerived], [true, false]
    )
    func unusableVaultAnswersNo(state: SUT, isMarkedLocally: Bool) {
        #expect(!state.hasAccount(markedLocally: isMarkedLocally))
    }

    @Test("A state that read nothing answers from the mark", arguments: [true, false])
    func nothingReadAnswersFromTheMark(isMarkedLocally: Bool) {
        #expect(SUT.unresolved.hasAccount(markedLocally: isMarkedLocally) == isMarkedLocally)
    }

    // MARK: - Recording

    @Test("A confirmed vault is recorded", arguments: [SUT.ready(.stub), .rekeyRequired(.stub)])
    func recordsConfirmedVault(state: SUT) {
        #expect(state.presenceRecord == .exists)
    }

    @Test("A confirmed absence erases the record")
    func erasesConfirmedAbsence() {
        #expect(SUT.notOnboarded.presenceRecord == .absent)
    }

    @Test(
        "A state that confirmed nothing leaves the record alone",
        arguments: [SUT.unresolved, .coldOwnerNotDerived]
    )
    func keepsRecordWhenNothingConfirmed(state: SUT) {
        #expect(state.presenceRecord == .unchanged)
    }
}

// MARK: - Helpers

private extension CollectiblesVaultInfo {
    static let stub = CollectiblesVaultInfo(
        vaultAddress: "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA",
        sessionKey: Data(repeating: 1, count: 32),
        perSpinCap: 300_000_000,
        dailyCap: 1_000_000_000,
        spentToday: 0,
        dayIndex: 20_354
    )
}
