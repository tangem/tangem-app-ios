//
//  PendingJointAccountSelectionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

@Suite("Tests for picking the joint accounts the main screen shows a plate for")
struct PendingJointAccountSelectionTests {
    /// Kept by the suite because the models hold it weakly, and a new one is made per test the way every stored
    /// property of a suite is.
    private let delegate = JointAccountModelDelegateMock()

    @Test("Only the joint accounts that are waiting are picked out of the account list")
    func aggregatorPicksTheWaitingJointAccountsOnly() {
        let waiting = makeJointAccount(status: .pending)
        let working = makeJointAccount(status: .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"))
        let standard = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })

        let accountModels: [AccountModel] = [.standard(.single(standard)), .joint([waiting, working])]

        let picked = JointAccountCryptoModelsAggregator.pendingJointAccountModels(from: accountModels)

        #expect(picked.map { $0.id } == [waiting.id])
    }

    @Test("Every joint account is reported when the status is not what is being asked about")
    func aggregatorReportsEveryJointAccount() {
        let waiting = makeJointAccount(status: .pending)
        let working = makeJointAccount(status: .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"))
        let standard = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })

        let accountModels: [AccountModel] = [.standard(.single(standard)), .joint([waiting, working])]

        let picked = JointAccountCryptoModelsAggregator.jointAccountModels(from: accountModels)

        #expect(picked.map { $0.id } == [waiting.id, working.id])
    }

    @Test("A wallet that shares no account at all is reported as having none waiting")
    func aggregatorReportsNothingWithoutJointAccounts() {
        let standard = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })

        let picked = JointAccountCryptoModelsAggregator.pendingJointAccountModels(
            from: [.standard(.single(standard))]
        )

        #expect(picked.isEmpty)
    }
}

// MARK: - Helpers

private extension PendingJointAccountSelectionTests {
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
