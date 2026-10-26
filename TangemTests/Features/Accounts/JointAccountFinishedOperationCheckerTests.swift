//
//  JointAccountFinishedOperationCheckerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

// MARK: - Tests

@Suite("Tests for telling a finished joint account operation from one in flight")
struct JointAccountFinishedOperationCheckerTests {
    private let sut = JointAccountFinishedOperationChecker()

    @Test("An operation collecting signatures or being executed is not finished", arguments: [JointAccountOperationStatus.awaitingSignatures, .pending])
    func operationInFlightIsNotFinished(status: JointAccountOperationStatus) {
        #expect(!sut.isFinished(JointAccountCompositionFixture.coinTransfer(status: status)))
    }

    @Test("An operation at any other stage, an unknown one included, is finished", arguments: [JointAccountOperationStatus.executed, .failed, .cancelled, .unknown])
    func operationAtAnyOtherStageIsFinished(status: JointAccountOperationStatus) {
        #expect(sut.isFinished(JointAccountCompositionFixture.coinTransfer(status: status)))
    }
}
