//
//  JointOperationHistoryOverwriteRuleTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("JointOperationHistoryOverwriteRule")
struct JointOperationHistoryOverwriteRuleTests {
    private let sut = JointOperationHistoryOverwriteRule()

    @Test("A stage the API reports and this version does not know is not written", arguments: Self.storedStatuses)
    func unknownFromRemoteIsSkipped(stored: JointAccountOperationStatus?) {
        #expect(!sut.shouldWrite(.unknown, from: .remote, over: stored))
    }

    @Test(
        "A known stage from the API is written over whatever is stored",
        arguments: Self.knownStatuses,
        Self.storedStatuses
    )
    func knownFromRemoteIsAlwaysWritten(incoming: JointAccountOperationStatus, stored: JointAccountOperationStatus?) {
        #expect(sut.shouldWrite(incoming, from: .remote, over: stored))
    }

    @Test(
        "A local in-flight operation does not roll back a finished one or one of a stage this version does not know",
        arguments: [JointAccountOperationStatus.awaitingSignatures, .pending],
        [JointAccountOperationStatus.executed, .failed, .cancelled, .unknown]
    )
    func localInFlightOverFinishedIsSkipped(incoming: JointAccountOperationStatus, stored: JointAccountOperationStatus) {
        #expect(!sut.shouldWrite(incoming, from: .local, over: stored))
    }

    @Test(
        "A local in-flight operation is written over an in-flight or a missing one",
        arguments: [JointAccountOperationStatus.awaitingSignatures, .pending],
        [JointAccountOperationStatus?.none, .awaitingSignatures, .pending]
    )
    func localInFlightOverInFlightIsWritten(incoming: JointAccountOperationStatus, stored: JointAccountOperationStatus?) {
        #expect(sut.shouldWrite(incoming, from: .local, over: stored))
    }

    @Test(
        "A local finished operation is written over whatever is stored",
        arguments: [JointAccountOperationStatus.executed, .failed, .cancelled],
        Self.storedStatuses
    )
    func localFinishedIsAlwaysWritten(incoming: JointAccountOperationStatus, stored: JointAccountOperationStatus?) {
        #expect(sut.shouldWrite(incoming, from: .local, over: stored))
    }

    @Test("A local operation of an unknown stage is not written", arguments: Self.storedStatuses)
    func unknownFromLocalIsSkipped(stored: JointAccountOperationStatus?) {
        #expect(!sut.shouldWrite(.unknown, from: .local, over: stored))
    }
}

// MARK: - Helpers

private extension JointOperationHistoryOverwriteRuleTests {
    static let knownStatuses: [JointAccountOperationStatus] = [.awaitingSignatures, .pending, .executed, .failed, .cancelled]
    static let storedStatuses: [JointAccountOperationStatus?] = [nil, .awaitingSignatures, .pending, .executed, .failed, .cancelled, .unknown]
}
