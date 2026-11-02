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
    case confirming(canActivate: Bool)
    case completed

    init(status: JointAccountStatus, slots: [JointAccountSlot], isCreator: Bool, canActivate: Bool, now: Date) {
        switch status {
        case .pending:
            let collecting = Collecting(slots: slots, isCreator: isCreator, now: now)
            self = .collecting(collecting, isCreator: isCreator)
        case .confirming:
            self = .confirming(canActivate: canActivate)
        case .active, .cancelled, .unknown:
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
        let freeSlots = slots.compactMap(Self.emptyType(of:))

        guard freeSlots.isNotEmpty else {
            self = .everyoneJoined
            return
        }

        let notInvitedCount = freeSlots.filter { !Self.isInvited($0, at: now) }.count

        guard isCreator, notInvitedCount > 0 else {
            self = .awaitingMembers(count: freeSlots.count)
            return
        }

        let isAnyInviteIssued = slots.members.count > 1 || freeSlots.contains { Self.inviteExpiresAt(of: $0) != nil }

        guard isAnyInviteIssued else {
            self = .notInvited(count: notInvitedCount)
            return
        }

        self = .moreNotInvited(count: notInvitedCount)
    }

    static func emptyType(of slot: JointAccountSlot) -> JointAccountSlot.EmptyType? {
        switch slot {
        case .empty(_, let type): type
        case .member: nil
        }
    }

    static func isInvited(_ type: JointAccountSlot.EmptyType, at now: Date) -> Bool {
        guard let expiresAt = inviteExpiresAt(of: type) else {
            return false
        }

        return expiresAt > now
    }

    static func inviteExpiresAt(of type: JointAccountSlot.EmptyType) -> Date? {
        switch type {
        case .reinvitable(let previousInviteExpiresAt): previousInviteExpiresAt
        case .notInvitable, .invitable: nil
        }
    }
}
