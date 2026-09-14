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
        let account = Self.makeJointAccount(status: status, membersCount: 3, takenSlotsCount: 1, invitesCount: 2)

        #expect(account.isAwaitingActivation == isAwaitingActivation)
    }

    @Test("A status this version has never heard of leaves the account looking like one that works")
    func unfamiliarStatusIsNotAwaitingActivation() {
        let account = Self.makeJointAccount(
            status: .unknown,
            membersCount: 3,
            takenSlotsCount: 1,
            invitesCount: 2
        )

        #expect(!account.isAwaitingActivation)
    }

    @Test("Inviting takes both a slot to fill and an invite to fill it with")
    func invitingTakesAFreeSlotAndAnInvite() {
        let creator = Self.makeJointAccount(status: .pending, membersCount: 3, takenSlotsCount: 1, invitesCount: 2)
        // A member was never handed invites of their own, so they have no one to bring in
        let member = Self.makeJointAccount(status: .pending, membersCount: 3, takenSlotsCount: 1, invitesCount: 0)
        // The creator of a full composition still holds the invites it was created with, but nothing to spend them on
        let full = Self.makeJointAccount(status: .confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"), membersCount: 3, takenSlotsCount: 3, invitesCount: 2)

        #expect(creator.canInviteMembers)
        #expect(!member.canInviteMembers)
        #expect(!full.canInviteMembers)
    }

    @Test("Activating is offered to the creator of a full composition and to no one else")
    func activatingTakesTheStageAndTheCreator() {
        let creator = Self.makeJointAccount(
            status: .confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"),
            membersCount: 3,
            takenSlotsCount: 3,
            invitesCount: 2
        )
        // A member holds no invites, which is what tells them apart from the creator
        let member = Self.makeJointAccount(
            status: .confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"),
            membersCount: 3,
            takenSlotsCount: 3,
            invitesCount: 0
        )
        let stillFilling = Self.makeJointAccount(status: .pending, membersCount: 3, takenSlotsCount: 1, invitesCount: 2)

        #expect(creator.canActivate)
        #expect(!member.canActivate)
        #expect(!stillFilling.canActivate)
    }

    /// The button stays: the address is the backend's to name, and hiding the only action the screen has would
    /// leave the creator with nothing and no reason why.
    @Test("An announced address the answer left out does not take the activate button with it")
    func activatingIsOfferedWithoutAnAnnouncedAddress() {
        let account = Self.makeJointAccount(
            status: .confirming(safeAddress: nil),
            membersCount: 3,
            takenSlotsCount: 3,
            invitesCount: 2
        )

        #expect(account.canActivate)
        #expect(account.announcedSafeAddress == nil)
    }

    @Test("More members than the count says leaves no free slots rather than a negative number of them")
    func freeSlotsNeverGoNegative() {
        let account = Self.makeJointAccount(status: .pending, membersCount: 2, takenSlotsCount: 3, invitesCount: 1)

        #expect(account.freeSlotsCount == 0)
        #expect(!account.canInviteMembers)
    }
}

// MARK: - Helpers

private extension JointAccountActivationStateTests {
    static func makeJointAccount(
        status: JointAccountStatus,
        membersCount: Int,
        takenSlotsCount: Int,
        invitesCount: Int
    ) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIndex: 1,
            policy: JointAccountPolicy(membersCount: membersCount, signersCount: 2),
            status: status,
            members: (0 ..< takenSlotsCount).map { index in
                JointAccountMember(
                    name: "Member \(index)",
                    address: "0x0000000000000000000000000000000000000000",
                    role: index == 0 ? .creator : .member(inviteId: "invite-\(index)")
                )
            },
            invites: (0 ..< invitesCount).map { JointAccountInvite(id: "invite-\($0)") }
        )
    }
}
