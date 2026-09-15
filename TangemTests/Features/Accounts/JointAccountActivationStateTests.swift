//
//  JointAccountActivationStateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

@Suite("Tests for a joint account before it is activated")
struct JointAccountActivationStateTests {
    /// Kept by the suite because the models hold it weakly, and a new one is made per test the way every stored
    /// property of a suite is.
    private let delegate = JointAccountModelDelegateMock()

    @Test(
        "An account is still being put together until every slot is taken and the creator has activated it",
        arguments: [
            (JointAccountStatus.pending, true),
            (.confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"), true),
            (.active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"), false),
            (.cancelled, false),
        ]
    )
    func awaitingActivationFollowsTheStatus(status: JointAccountStatus, isAwaitingActivation: Bool) {
        let account = makeJointAccount(status: status)

        #expect(account.isAwaitingActivation == isAwaitingActivation)
    }

    @Test("A status this version has never heard of leaves the account looking like one that works")
    func unfamiliarStatusIsNotAwaitingActivation() {
        let account = makeJointAccount(status: .unknown)

        #expect(!account.isAwaitingActivation)
    }
}

// MARK: - Helpers

private extension JointAccountActivationStateTests {
    func makeJointAccount(status: JointAccountStatus) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 3, signersCount: 2),
            accountStatus: status,
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(),
            delegate: delegate
        )
    }
}
