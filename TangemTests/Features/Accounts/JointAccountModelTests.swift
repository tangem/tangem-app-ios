//
//  JointAccountModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Tests for what a joint account says about its own slots")
struct JointAccountModelTests {
    // MARK: - Unused invites

    @Test("Every invite is unused while nobody has walked in with one")
    func allInvitesAreUnusedWithoutMembers() {
        let account = makeAccount(
            membersCount: 3,
            members: [creator],
            inviteIds: ["AA", "BB"]
        )

        #expect(account.unusedInvites.map(\.id) == ["AA", "BB"])
    }

    @Test("The invite a member walked in with is no longer handed out")
    func takenInviteIsLeftOut() {
        let account = makeAccount(
            membersCount: 3,
            members: [creator, member(inviteId: "AA")],
            inviteIds: ["AA", "BB"]
        )

        #expect(account.unusedInvites.map(\.id) == ["BB"])
    }

    @Test("An invite is matched to its member regardless of how either is cased")
    func takenInviteIsMatchedCaseInsensitively() {
        let account = makeAccount(
            membersCount: 3,
            members: [creator, member(inviteId: "aa")],
            inviteIds: ["AA", "BB"]
        )

        #expect(account.unusedInvites.map(\.id) == ["BB"])
    }

    @Test("A slot left free with no invite to open it is not offered")
    func freeSlotWithoutAnInviteIsNotOffered() {
        let account = makeAccount(
            membersCount: 3,
            members: [creator],
            inviteIds: []
        )

        #expect(account.freeSlotsCount == 2)
        #expect(account.unusedInvites.isEmpty)
    }

    // MARK: - Helpers

    private var creator: JointAccountMember {
        JointAccountMember(name: "Isaac", address: "0xcreator", role: .creator)
    }

    private func member(inviteId: String) -> JointAccountMember {
        JointAccountMember(name: "Member", address: "0xmember", role: .member(inviteId: inviteId))
    }

    private func makeAccount(
        membersCount: Int,
        members: [JointAccountMember],
        inviteIds: [String]
    ) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIndex: 1,
            policy: JointAccountPolicy(membersCount: membersCount, signersCount: 2),
            status: .pending,
            members: members,
            invites: inviteIds.map(JointAccountInvite.init(id:))
        )
    }
}
