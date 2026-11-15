//
//  JointAccountMembersPhaseTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

private let now = Date(timeIntervalSince1970: 1_800_000_000)
private let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"

@Suite("Joint account members phase")
struct JointAccountMembersPhaseTests {
    // MARK: - Collecting

    @Test("The creator has members to invite before any invite is issued")
    func creatorInvitesBeforeAnyInvite() {
        let slots = [Self.member(0, isMe: true), Self.freeSlot(1, .invitable), Self.freeSlot(2, .invitable)]

        let phase = makePhase(status: .pending, slots: slots, isCreator: true)

        #expect(phase == .collecting(.notInvited(count: 2), isCreator: true))
    }

    @Test(
        "A free slot without a live invite still has to be invited",
        arguments: [
            JointAccountSlot.EmptyType.invitable,
            .reinvitable(previousInviteExpiresAt: now.addingTimeInterval(-1)),
            .reinvitable(previousInviteExpiresAt: now),
        ]
    )
    func freeSlotWithoutLiveInviteIsNotInvited(type: JointAccountSlot.EmptyType) {
        let slots = [Self.member(0, isMe: true), Self.freeSlot(1, Self.invited), Self.freeSlot(2, type)]

        let phase = makePhase(status: .pending, slots: slots, isCreator: true)

        #expect(phase == .collecting(.moreNotInvited(count: 1), isCreator: true))
    }

    @Test("The creator waits for the members once every free slot has a live invite")
    func creatorWaitsWhenEveryoneIsInvited() {
        let slots = [Self.member(0, isMe: true), Self.freeSlot(1, Self.invited), Self.freeSlot(2, Self.invited)]

        let phase = makePhase(status: .pending, slots: slots, isCreator: true)

        #expect(phase == .collecting(.awaitingMembers(count: 2), isCreator: true))
    }

    @Test("A member waits for as many members as there are free slots")
    func memberWaitsForFreeSlots() {
        let slots = [Self.member(0), Self.member(1, isMe: true), Self.freeSlot(2, .notInvitable), Self.freeSlot(3, .notInvitable)]

        let phase = makePhase(status: .pending, slots: slots, isCreator: false)

        #expect(phase == .collecting(.awaitingMembers(count: 2), isCreator: false))
    }

    @Test("Every slot taken means everyone has joined", arguments: [true, false])
    func everyoneJoinedWhenNoSlotIsFree(isCreator: Bool) {
        let slots = [Self.member(0, isMe: isCreator), Self.member(1, isMe: !isCreator)]

        let phase = makePhase(status: .pending, slots: slots, isCreator: isCreator)

        #expect(phase == .collecting(.everyoneJoined, isCreator: isCreator))
    }

    // MARK: - Confirming

    @Test("A member who has not confirmed the address can confirm it")
    func unconfirmedMemberCanConfirm() {
        let slots = [Self.member(0, isMe: true), Self.member(1, isConfirmed: true)]

        let phase = makePhase(status: .confirming(safeAddress: safeAddress), slots: slots, isCreator: true)

        #expect(phase == .confirming(canConfirm: true, unconfirmedCount: 1))
    }

    @Test("A member who has confirmed the address cannot confirm it again")
    func confirmedMemberCannotConfirm() {
        let slots = [Self.member(0, isMe: true, isConfirmed: true), Self.member(1), Self.member(2)]

        let phase = makePhase(status: .confirming(safeAddress: safeAddress), slots: slots, isCreator: true)

        #expect(phase == .confirming(canConfirm: false, unconfirmedCount: 2))
    }

    @Test("Nobody can confirm, or is waited for, while the backend has not named the address")
    func noConfirmationWithoutAddress() {
        let slots = [Self.member(0, isMe: true), Self.member(1)]

        let phase = makePhase(status: .confirming(safeAddress: nil), slots: slots, isCreator: true)

        #expect(phase == .confirming(canConfirm: false, unconfirmedCount: 0))
    }

    // MARK: - Other stages

    @Test(
        "An account past putting together is completed",
        arguments: [JointAccountStatus.active(safeAddress: safeAddress), .untrusted, .cancelled, .unknown]
    )
    func accountPastPuttingTogetherIsCompleted(status: JointAccountStatus) {
        let slots = [Self.member(0, isMe: true), Self.freeSlot(1, .invitable)]

        let phase = makePhase(status: status, slots: slots, isCreator: true)

        #expect(phase == .completed)
    }
}

// MARK: - Helpers

private extension JointAccountMembersPhaseTests {
    static let invited = JointAccountSlot.EmptyType.reinvitable(previousInviteExpiresAt: now.addingTimeInterval(60 * 60))

    func makePhase(status: JointAccountStatus, slots: [JointAccountSlot], isCreator: Bool) -> JointAccountMembersPhase {
        JointAccountMembersPhase(status: status, slots: slots, isCreator: isCreator, now: now)
    }

    static func member(_ index: Int, isMe: Bool = false, isConfirmed: Bool = false) -> JointAccountSlot {
        let member = JointAccountMember(
            name: "Member \(index)",
            address: "0x\(index)",
            role: index == 0 ? .creator : .member,
            isMe: isMe,
            signature: isConfirmed ? "0xsignature" : nil
        )
        let type: JointAccountSlot.MemberType = isConfirmed ? .confirmed : .joined

        return .member(member, type)
    }

    static func freeSlot(_ index: Int, _ type: JointAccountSlot.EmptyType) -> JointAccountSlot {
        .empty(JointAccountMemberSlotID(index), type)
    }
}
