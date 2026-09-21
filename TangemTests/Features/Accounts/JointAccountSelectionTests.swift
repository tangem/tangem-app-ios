//
//  JointAccountSelectionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

@Suite("Tests for taking the joint accounts a wallet takes part in out of its account list")
struct JointAccountSelectionTests {
    /// Kept by the suite because the models hold it weakly, and a new one is made per test the way every stored
    /// property of a suite is.
    private let delegate = JointAccountModelDelegateMock()

    @Test("Only the joint accounts that are waiting are picked out of the account list")
    func aggregatorPicksTheWaitingJointAccountsOnly() {
        let waiting = makeJointAccount(status: .pending)
        let working = makeJointAccount(status: .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"))
        let standard = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })

        let accountModels: [AccountModel] = [.standard(.single(standard)), .joint([waiting, working])]

        let picked: [any JointAccountModel] = AccountModelsAggregator(.joint(.pending)).models(from: accountModels)

        #expect(picked.map { $0.id } == [waiting.id])
    }

    @Test("Only the joint accounts that are up and running are picked out of the account list")
    func aggregatorPicksTheWorkingJointAccountsOnly() {
        let waiting = makeJointAccount(status: .pending)
        let working = makeJointAccount(status: .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"))
        let standard = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })

        let accountModels: [AccountModel] = [.standard(.single(standard)), .joint([waiting, working])]

        let picked: [any JointAccountModel] = AccountModelsAggregator(.joint(.active)).models(from: accountModels)

        #expect(picked.map { $0.id } == [working.id])
    }

    @Test("Asked for the joint accounts without naming a state, the aggregator picks every one of them")
    func aggregatorPicksEveryJointAccountByDefault() {
        let waiting = makeJointAccount(status: .pending)
        let working = makeJointAccount(status: .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"))
        let standard = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })

        let accountModels: [AccountModel] = [.standard(.single(standard)), .joint([waiting, working])]

        let picked: [any CryptoAccountModel] = AccountModelsAggregator(.joint).models(from: accountModels)

        #expect(picked.map { $0.id } == [waiting.id, working.id])
    }

    @Test("Kinds asked for together are answered kind by kind, in the order they were asked for")
    func aggregatorAnswersKindByKind() {
        let waiting = makeJointAccount(status: .pending)
        let working = makeJointAccount(status: .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"))
        let standard = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })

        // Joint first, so that the answer is shown to follow the kinds rather than the list they arrived in
        let accountModels: [AccountModel] = [.joint([waiting, working]), .standard(.single(standard))]

        let picked: [any CryptoAccountModel] = AccountModelsAggregator(.crypto, .joint).models(from: accountModels)

        #expect(picked.map { $0.id } == [standard.id, waiting.id, working.id])
    }

    @Test("A wallet that shares no account at all is reported as having none waiting")
    func aggregatorReportsNothingWithoutJointAccounts() {
        let standard = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })

        let picked: [any JointAccountModel] = AccountModelsAggregator(.joint(.pending)).models(
            from: [.standard(.single(standard))]
        )

        #expect(picked.isEmpty)
    }
}

// MARK: - Helpers

private extension JointAccountSelectionTests {
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
