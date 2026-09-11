//
//  RemoteJointAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

/// A joint account as the endpoint keeps it, which is everything about one except the invites — those a wallet
/// remembers for itself in `StoredJointAccountInvites`, since they are handed out once and never reported again.
struct RemoteJointAccount: Equatable {
    let cryptoAccountId: String
    let membersCount: Int
    let threshold: Int
    /// One and the same across every supported EVM network. Absent until every slot is taken.
    let address: String?
    let status: JointAccountStatus
    /// Only the slots that are taken, in the order they were taken, the creator first.
    let members: [StoredJointAccount.Member]
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
            "address": address?.masked() ?? "none",
            "status": status,
            "Taken slots count": members.count,
        ])
    }
}
