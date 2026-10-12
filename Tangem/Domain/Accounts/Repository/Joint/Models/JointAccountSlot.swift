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
    case member(JointAccountMember)
    /// - Note: Nil on a wallet that holds no invite for the slot — anyone's but the creator's, and the creator's own
    /// once every invite has been spent or lost.
    case empty(invite: JointAccountInvite?)
}

extension JointAccountSlot {
    var member: JointAccountMember? {
        switch self {
        case .member(let member): member
        case .empty: nil
        }
    }

    var invite: JointAccountInvite? {
        switch self {
        case .member: nil
        case .empty(let invite): invite
        }
    }
}

// MARK: - Collection + JointAccountSlot

extension Collection where Element == JointAccountSlot {
    var members: [JointAccountMember] {
        compactMap { $0.member }
    }
}
