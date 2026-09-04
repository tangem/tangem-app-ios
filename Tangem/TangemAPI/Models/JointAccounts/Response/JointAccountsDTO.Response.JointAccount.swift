//
//  JointAccountsDTO.Response.JointAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Response {
    /// The account as every endpoint describes it, whether it has just been created, joined, activated or merely
    /// read: creating is the one answer that fills the invites in, and joining the last free slot is what brings
    /// the address and the status the endpoint works out from the full composition.
    struct JointAccount: Decodable {
        struct Member: Decodable {
            let name: String
            let address: String
            let role: JointAccountMemberRole
            /// The invite this member redeemed to take their slot; the creator's slot never had one. What lets the
            /// creator tell, while the account is pending, which invite went to whom.
            let inviteId: String?
        }

        struct Invite: Decodable {
            let id: String
        }

        let cryptoAccountId: String
        let membersCount: Int
        let threshold: Int
        /// Absent until every slot is taken.
        let safeAddress: String?
        let status: JointAccountStatus
        let members: [Member]
        /// Only ever answers creating the account — see `JointAccountInvite`.
        let invites: [Invite]?
        /// The unfinished operations, at most one per network.
        let operations: [Operation]?
    }
}
