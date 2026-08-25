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
        /// - Warning: Its letter case carries an EIP-55 checksum rather than identity, so two of these are never
        /// compared as strings.
        let address: String
        let role: JointAccountMemberRole
    }

    /// The wallet's own account this joint one is joined with, and the only field the two endpoints describing it share.
    let cryptoAccountId: String
    /// Both fixed when the account is created.
    let membersCount: Int
    let threshold: Int
    /// One and the same across every supported EVM network. Absent until every slot is taken.
    let address: String?
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
            address: remote.address,
            status: remote.status,
            members: remote.members
        )
    }
}
