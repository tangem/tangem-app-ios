//
//  JointAccountMembersPhase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemMacro

@RawCaseName
enum JointAccountMembersPhase: Equatable {
    case collecting(Collecting, isCreator: Bool)
    case confirming(canConfirm: Bool, unconfirmedCount: Int)
    case completed

    init(status: JointAccountStatus, slots: [JointAccountSlot], isCreator: Bool, now: Date) {
        switch status {
        case .pending:
            let collecting = Collecting(slots: slots, isCreator: isCreator, now: now)
            self = .collecting(collecting, isCreator: isCreator)
        case .confirming(.some):
            let me = slots.members.first(where: \.isMe)
            let canConfirm = me.map { $0.signature == nil } ?? false
            let unconfirmedCount = slots.members.filter { $0.signature == nil }.count
            self = .confirming(canConfirm: canConfirm, unconfirmedCount: unconfirmedCount)
        case .confirming(.none):
            self = .confirming(canConfirm: false, unconfirmedCount: 0)
        case .active, .untrusted, .cancelled, .unknown:
            self = .completed
        }
    }
}

// MARK: - Collecting

extension JointAccountMembersPhase {
    enum Collecting: Equatable {
        case everyoneJoined
        case awaitingMembers(count: Int)
        case notInvited(count: Int)
        case moreNotInvited(count: Int)
    }
}

private extension JointAccountMembersPhase.Collecting {
    init(slots: [JointAccountSlot], isCreator: Bool, now: Date) {
        let freeSlots = slots.compactMap(\.emptyType)

        guard freeSlots.isNotEmpty else {
            self = .everyoneJoined
            return
        }

        let notInvitedCount = freeSlots.filter { !$0.isInvited(at: now) }.count

        guard isCreator, notInvitedCount > 0 else {
            self = .awaitingMembers(count: freeSlots.count)
            return
        }

        let isAnyInviteIssued = slots.members.count > 1 || freeSlots.contains { $0.inviteExpiresAt != nil }

        guard isAnyInviteIssued else {
            self = .notInvited(count: notInvitedCount)
            return
        }

        self = .moreNotInvited(count: notInvitedCount)
    }
}
