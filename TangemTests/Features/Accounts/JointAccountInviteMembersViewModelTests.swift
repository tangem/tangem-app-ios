//
//  JointAccountInviteMembersViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
@testable import Tangem

@Suite("Tests for the rows the joint account composition is shown by")
@MainActor
struct JointAccountInviteMembersViewModelTests {
    @Test("Everyone who has taken a slot has a row of their own")
    func everyMemberIsShown() {
        let viewModel = makeViewModel(
            membersCount: 3,
            members: [creator, member(name: "Bob", inviteId: "AA")],
            inviteIds: ["AA", "BB"]
        )

        #expect(viewModel.content.members.map(\.name) == ["Isaac", "Bob"])
        #expect(viewModel.content.joinedMembersCount == 2)
        #expect(viewModel.content.totalMembersCount == 3)
    }

    @Test("The wallet holding the invites is the creator's, and its own row says so")
    func creatorRowNamesThisWallet() {
        let creatorSide = makeViewModel(membersCount: 2, members: [creator], inviteIds: ["AA"])
        let memberSide = makeViewModel(membersCount: 2, members: [creator], inviteIds: [])

        #expect(creatorSide.content.members.first?.role.contains(Localization.jointAccountMembersRoleYou) == true)
        #expect(memberSide.content.members.first?.role == Localization.jointAccountInviteMembersCreator)
    }

    @Test("A slot somebody was invited into is a member rather than an invitation waiting to be sent")
    func joinedMemberIsNotAFreeSlot() {
        let viewModel = makeViewModel(
            membersCount: 2,
            members: [creator, member(name: "Bob", inviteId: "AA")],
            inviteIds: ["AA"]
        )

        #expect(viewModel.content.members.count == 2)
        #expect(viewModel.content.freeSlots.isEmpty)
    }

    @Test("Every free slot is shown, and the invite it is opened with goes to it alone")
    func freeSlotsCarryAnInviteEach() {
        let viewModel = makeViewModel(membersCount: 4, members: [creator], inviteIds: ["AA", "BB", "CC"])

        #expect(
            viewModel.content.freeSlots.map { $0.inviteURL?.absoluteString } == [
                "https://tangem.com/joint-account/join/AA",
                "https://tangem.com/joint-account/join/BB",
                "https://tangem.com/joint-account/join/CC",
            ]
        )
    }

    @Test("A slot this wallet holds no invite for is shown all the same, with nothing to invite anybody by")
    func freeSlotWithoutAnInviteIsStillShown() {
        let viewModel = makeViewModel(membersCount: 3, members: [creator], inviteIds: [])

        #expect(viewModel.content.freeSlots.count == 2)
        #expect(viewModel.content.freeSlots.allSatisfy { $0.inviteURL == nil })
    }

    // MARK: - Helpers

    private var creator: JointAccountMember {
        JointAccountMember(name: "Isaac", address: "0xcreator", role: .creator)
    }

    private func member(name: String, inviteId: String) -> JointAccountMember {
        JointAccountMember(name: name, address: "0x\(name)", role: .member(inviteId: inviteId))
    }

    private func makeViewModel(
        membersCount: Int,
        members: [JointAccountMember],
        inviteIds: [String]
    ) -> JointAccountInviteMembersViewModel {
        let jointAccount = CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            policy: JointAccountPolicy(membersCount: membersCount, signersCount: 2),
            status: .pending,
            members: members,
            invites: inviteIds.map(JointAccountInvite.init(id:))
        )

        return JointAccountInviteMembersViewModel(jointAccount: jointAccount, coordinator: nil)
    }
}
