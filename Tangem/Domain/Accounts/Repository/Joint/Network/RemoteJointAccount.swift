//
//  RemoteJointAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// A joint account as the endpoint keeps it.
struct RemoteJointAccount: Equatable {
    struct Invite: Equatable {
        let slot: JointAccountMemberSlotID
        let expiresAt: Date
    }

    let cryptoAccountId: String
    let membersCount: Int
    let threshold: Int
    let status: JointAccountStatus
    /// Only the slots that are taken, in the order they were taken, the creator first.
    let members: [StoredJointAccount.Member]
    let invites: [Invite]
    /// The unfinished operations, at most one per network.
    let operations: [JointAccountOperation]
}

// MARK: - CustomStringConvertible protocol conformance

extension RemoteJointAccount: CustomStringConvertible {
    /// - Warning: Counts the members rather than naming them. What they are called and the address each of them signs
    /// with belong to other people's wallets, and this wallet has no business writing either into a file.
    var description: String {
        objectDescription("RemoteJointAccount", userInfo: [
            "cryptoAccountId": cryptoAccountId.masked(),
            "membersCount": membersCount,
            "threshold": threshold,
            "status": status,
            "Taken slots count": members.count,
            "Invites count": invites.count,
            "Operations count": operations.count,
        ])
    }
}
