//
//  StoredJointAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// What a joint account has on top of the entry the wallet's account list holds for it, which is where its name, its
/// icon and its tokens live instead.
struct StoredJointAccount: Codable, Equatable {
    struct Member: Codable, Equatable {
        /// From 1 to 25 characters.
        let name: String
        /// - Warning: The endpoint keeps these in lower case while the app computes the checksummed form, so two of
        /// these are only ever compared case-insensitively, never as strings.
        let address: String
        let role: JointAccountMemberRole
        /// The invite this member redeemed to take their slot. Absent on the creator's slot, which never had one, on
        /// every slot of an activated account, which the endpoint describes without its invites, and throughout a
        /// record stored before the endpoint learnt to report them at all.
        let inviteId: String?
    }

    /// The wallet's own account this joint one is joined with, and the only field the two endpoints describing it share.
    let cryptoAccountId: String
    /// Both fixed when the account is created.
    let membersCount: Int
    let threshold: Int
    let status: JointAccountStatus
    /// Only the slots that are taken, in the order they were taken, the creator first.
    let members: [Member]
}

// MARK: - Convenience

extension StoredJointAccount {
    init(remote: RemoteJointAccount) {
        self.init(
            cryptoAccountId: remote.cryptoAccountId,
            membersCount: remote.membersCount,
            threshold: remote.threshold,
            status: remote.status,
            members: remote.members
        )
    }
}
