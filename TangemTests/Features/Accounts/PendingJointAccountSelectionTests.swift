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
    @Test("Only the joint accounts that are waiting are picked out of the account list")
    func aggregatorPicksTheWaitingJointAccountsOnly() {
        let waiting = Self.makeJointAccount(status: .pending, membersCount: 3, takenSlotsCount: 1)
        let working = Self.makeJointAccount(status: .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"), membersCount: 3, takenSlotsCount: 3)
        let standard = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })

        let accountModels: [AccountModel] = [.standard(.single(standard)), .joint([waiting, working])]

        let picked = JointAccountCryptoModelsAggregator.pendingJointAccountModels(from: accountModels)

        #expect(picked.map { $0.id } == [waiting.id])
    }

    @Test("Every joint account is reported when the status is not what is being asked about")
    func aggregatorReportsEveryJointAccount() {
        let waiting = Self.makeJointAccount(status: .pending, membersCount: 3, takenSlotsCount: 1)
        let working = Self.makeJointAccount(status: .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"), membersCount: 3, takenSlotsCount: 3)
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
    static func makeJointAccount(
        status: JointAccountStatus,
        membersCount: Int,
        takenSlotsCount: Int
    ) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            policy: JointAccountPolicy(membersCount: membersCount, signersCount: 2),
            status: status,
            members: (0 ..< takenSlotsCount).map { index in
                JointAccountMember(
                    name: "Member \(index)",
                    address: "0x0000000000000000000000000000000000000000",
                    role: index == 0 ? .creator : .member(inviteId: "invite-\(index)")
                )
            },
            invites: (0 ..< max(0, membersCount - takenSlotsCount)).map { JointAccountInvite(id: "invite-\($0)") }
        )
    }
}
