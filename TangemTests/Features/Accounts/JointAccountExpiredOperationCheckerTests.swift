//
//  JointAccountExpiredOperationCheckerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

@Suite("Tests for telling a finished joint account operation that has outstayed its day")
struct JointAccountExpiredOperationCheckerTests {
    private let sut = JointAccountExpiredOperationChecker()

    @Test("An operation still in flight never expires, whatever time it carries", arguments: [JointAccountOperationStatus.awaitingSignatures, .pending])
    func operationInFlightNeverExpires(status: JointAccountOperationStatus) {
        let operation = JointAccountCompositionFixture.coinTransfer(status: status, finishedAt: Self.now.addingTimeInterval(-Self.day * 2))

        #expect(!sut.isExpired(operation, now: Self.now))
    }

    @Test("A finished operation with no time of finishing is kept", arguments: [JointAccountOperationStatus.executed, .failed, .cancelled, .unknown])
    func finishedOperationWithoutATimeIsKept(status: JointAccountOperationStatus) {
        #expect(!sut.isExpired(JointAccountCompositionFixture.coinTransfer(status: status), now: Self.now))
    }

    @Test("A finished operation expires a day after it finished", arguments: [JointAccountOperationStatus.executed, .failed, .cancelled, .unknown])
    func finishedOperationExpiresAfterADay(status: JointAccountOperationStatus) {
        let justBefore = JointAccountCompositionFixture.coinTransfer(status: status, finishedAt: Self.now.addingTimeInterval(-Self.day + 1))
        let dayOld = JointAccountCompositionFixture.coinTransfer(status: status, finishedAt: Self.now.addingTimeInterval(-Self.day))

        #expect(!sut.isExpired(justBefore, now: Self.now))
        #expect(sut.isExpired(dayOld, now: Self.now))
    }
}

// MARK: - Helpers

private extension JointAccountExpiredOperationCheckerTests {
    static let now = Date(timeIntervalSince1970: 1_767_225_600)
    static let day: TimeInterval = 24 * 60 * 60
}
