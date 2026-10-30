//
//  JointAccountSlot.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// One of the account's slots, as many as the account was created with: taken by a member, or still free.
enum JointAccountSlot: Equatable {
    case empty(JointAccountMemberSlotID, EmptyType)
    case member(JointAccountMember, MemberType)
}

extension JointAccountSlot {
    enum EmptyType: Equatable {
        case notInvitable
        case invitable
        case reinvitable(previousInviteExpiresAt: Date)
    }

    enum MemberType: Equatable {
        case joined
        case awaitingConfirmation
        case confirmed
        case active
    }
}

extension JointAccountSlot {
    var member: JointAccountMember? {
        switch self {
        case .member(let member, _): member
        case .empty: nil
        }
    }
}

// MARK: - Collection + JointAccountSlot

extension Collection where Element == JointAccountSlot {
    var members: [JointAccountMember] {
        compactMap { $0.member }
    }
}
