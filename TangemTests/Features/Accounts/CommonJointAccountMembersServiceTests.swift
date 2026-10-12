//
//  CommonJointAccountMembersServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Tests for what a joint account's members service says about its slots")
struct CommonJointAccountMembersServiceTests {
    // MARK: - Slots

    @Test("Every invite opens a free slot while nobody has walked in with one")
    func allInvitesAreUnusedWithoutMembers() {
        let sut = Self.makeSUT(membersCount: 3, members: [Self.creator], inviteIds: ["AA", "BB"])

        #expect(Self.inviteIds(of: sut.slots) == [nil, "AA", "BB"])
    }

    @Test("The invite a member walked in with is no longer handed out")
    func takenInviteIsLeftOut() {
        let sut = Self.makeSUT(membersCount: 3, members: [Self.creator, Self.member(inviteId: "AA")], inviteIds: ["AA", "BB"])

        #expect(Self.inviteIds(of: sut.slots) == [nil, nil, "BB"])
    }

    @Test("An invite is matched to its member regardless of how either is cased")
    func takenInviteIsMatchedCaseInsensitively() {
        let sut = Self.makeSUT(membersCount: 3, members: [Self.creator, Self.member(inviteId: "aa")], inviteIds: ["AA", "BB"])

        #expect(Self.inviteIds(of: sut.slots) == [nil, nil, "BB"])
    }

    @Test("A slot left free with no invite to open it is still a slot, with nothing to offer")
    func freeSlotWithoutAnInviteIsStillASlot() {
        let sut = Self.makeSUT(membersCount: 3, members: [Self.creator], inviteIds: nil)

        #expect(sut.slots == [.member(Self.creator), .empty(invite: nil), .empty(invite: nil)])
    }

    @Test("An invite is handed on as the link that carries it")
    func inviteIsWrittenAsALink() {
        let sut = Self.makeSUT(membersCount: 2, members: [Self.creator], inviteIds: ["AA"])

        guard case .empty(let invite?) = sut.slots.last else {
            Issue.record("The free slot carries no invite")
            return
        }

        #expect(invite.url.absoluteString == "https://tangem.com/joint-account/join/AA")
    }

    @Test("More members than the count says leaves no free slots rather than a negative number of them")
    func freeSlotsNeverGoNegative() {
        let sut = Self.makeSUT(membersCount: 2, members: [Self.creator, Self.member(inviteId: "AA"), Self.member(inviteId: "BB")], inviteIds: ["CC"])

        #expect(sut.slots.count == 3)
        #expect(sut.slots.allSatisfy { $0.member != nil })
    }

    @Test("An account the store does not hold has no slots to speak of")
    func unknownAccountHasNoSlots() {
        let sut = JointAccountCompositionFixture.makeMembersService(repository: JointAccountsRepositoryStub())

        #expect(sut.slots.isEmpty)
        #expect(!sut.isCreatorDevice)
    }

    // MARK: - Inviting

    @Test("An invite is offered where a free slot and an invite for it meet, and nowhere else")
    func invitingTakesAFreeSlotAndAnInvite() {
        let creator = Self.makeSUT(membersCount: 3, members: [Self.creator], inviteIds: ["AA", "BB"])
        // A member was never handed invites of their own, so they have no one to bring in
        let member = Self.makeSUT(membersCount: 3, members: [Self.creator], inviteIds: nil)
        // The creator of a full composition still holds the invites it was created with, but nothing to spend them on
        let full = Self.makeSUT(
            membersCount: 2,
            members: [Self.creator, Self.member(inviteId: "AA")],
            inviteIds: ["AA"]
        )

        #expect(creator.slots.contains { $0.invite != nil })
        #expect(!member.slots.contains { $0.invite != nil })
        #expect(!full.slots.contains { $0.invite != nil })
    }

    // MARK: - The creator's wallet

    @Test("The wallet the account was created from is the one it left its invites with")
    func creatorDeviceIsTheOneHoldingTheInvites() {
        let creator = Self.makeSUT(membersCount: 3, members: [Self.creator], inviteIds: ["AA", "BB"])
        let member = Self.makeSUT(membersCount: 3, members: [Self.creator], inviteIds: nil)

        #expect(creator.isCreatorDevice)
        #expect(!member.isCreatorDevice)
    }

    @Test("An account created with every slot taken leaves its creator an empty record, and the creator's wallet all the same")
    func creatorDeviceOfAFullCompositionHoldsAnEmptyRecord() {
        let sut = Self.makeSUT(
            membersCount: 2,
            members: [Self.creator, Self.member(inviteId: "AA")],
            inviteIds: []
        )

        #expect(sut.isCreatorDevice)
    }
}

// MARK: - Helpers

private extension CommonJointAccountMembersServiceTests {
    static var creator: JointAccountMember {
        JointAccountMember(name: "Isaac", address: "0xcreator", role: .creator)
    }

    static func member(inviteId: String) -> JointAccountMember {
        JointAccountMember(name: "Member \(inviteId)", address: "0xmember\(inviteId)", role: .member(inviteId: inviteId))
    }

    static func makeSUT(membersCount: Int, members: [JointAccountMember], inviteIds: [String]?) -> CommonJointAccountMembersService {
        JointAccountCompositionFixture.makeMembersService(
            membersCount: membersCount,
            members: members,
            inviteIds: inviteIds
        )
    }

    /// The invite each slot is opened with; nil for a taken slot and for a free one this wallet holds no invite for.
    static func inviteIds(of slots: [JointAccountSlot]) -> [String?] {
        slots.map { slot in
            guard case .empty(let invite) = slot else {
                return nil
            }

            return invite?.id
        }
    }
}
