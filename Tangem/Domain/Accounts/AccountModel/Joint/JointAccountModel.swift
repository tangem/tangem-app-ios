//
//  JointAccountModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// One of the wallet's own accounts as far as its name, its icon and its tokens go — what it adds is the members it is
/// shared with and the rules they operate it by.
protocol JointAccountModel: CryptoAccountModel {
    var jointAccountConfig: JointAccountConfig { get }

    /// Only the slots that are taken, in the order they were taken, the creator first.
    var members: [JointAccountMember] { get }

    /// One per slot left free at creation, which is the only time they are ever handed out — see `JointAccountInvite`.
    /// - Note: Apart from the config because they are kept apart: the endpoint hands them out once and never reports
    /// them again, so re-reading the account cannot bring them back.
    /// - Warning: Count these rather than naming them wherever an account is described. An invite is the account's
    /// only access secret, so writing one into a log hands the slot it holds to whoever reads that log.
    var invites: [JointAccountInvite] { get }
}

// MARK: - Convenience

extension JointAccountModel {
    var creator: JointAccountMember? {
        members.first { $0.role == .creator }
    }

    /// The slots an invite is still waiting to fill.
    /// - Note: Clamped because the count and the members come as two independent fields of the same response.
    var freeSlotsCount: Int {
        max(0, jointAccountConfig.membersCount - members.count)
    }
}
