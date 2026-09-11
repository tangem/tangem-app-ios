//
//  JointAccountConfig.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

/// What a joint account is beyond the name, the icon and the tokens it holds as one of the wallet's own accounts.
struct JointAccountConfig: Equatable {
    /// How many slots the account has, the creator's included.
    let membersCount: Int
    /// How many of the members have to sign an operation for it to go through — the M of an M-of-N account.
    let signersCount: Int
    /// One and the same across every supported EVM network. Absent until every slot is taken.
    let address: String?
    let status: JointAccountStatus
    /// Only the slots that are taken, in the order they were taken, the creator first.
    let members: [JointAccountMember]
    /// One per slot left free at creation, which is the only time they are ever handed out — see `JointAccountInvite`.
    let invites: [JointAccountInvite]
}

// MARK: - CustomStringConvertible protocol conformance

extension JointAccountConfig: CustomStringConvertible {
    /// - Warning: Counts the invites rather than naming them. An invite is the account's only access secret, so writing
    /// one into a log hands the slot it holds to whoever reads that log.
    var description: String {
        objectDescription(
            "JointAccountConfig",
            userInfo: [
                "membersCount": membersCount,
                "signersCount": signersCount,
                "address": address ?? "none",
                "status": status,
                "Taken slots count": members.count,
                "Unused invites count": invites.count,
            ]
        )
    }
}

// MARK: - Convenience

extension JointAccountConfig {
    var creator: JointAccountMember? {
        members.first { $0.role == .creator }
    }

    /// The slots an invite is still waiting to fill.
    /// - Note: Clamped because the count and the members come as two independent fields of the same response.
    var freeSlotsCount: Int {
        max(0, membersCount - members.count)
    }
}
