//
//  JointAccountsDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A top-level namespace.
enum JointAccountsDTO {}

/// Shared DTO types used by more than one endpoint.
extension JointAccountsDTO {
    /// Described the same way whether the account has just been created or merely read.
    struct JointAccount: Decodable {
        struct Member: Decodable {
            let name: String
            let address: String
            let role: JointAccountMemberRole
        }

        struct Invite: Decodable {
            let id: String
        }

        let cryptoAccountId: String
        let membersCount: Int
        let threshold: Int
        /// Absent until every slot is taken.
        let address: String?
        /// - Note: Optional so that a response omitting it still reads.
        let status: JointAccountStatus?
        let members: [Member]
        /// Only ever answers creating the account — see `JointAccountInvite`.
        let invites: [Invite]?
    }
}

/// A second-level namespace, per endpoint.
extension JointAccountsDTO {
    enum Create {}
    enum List {}
}
