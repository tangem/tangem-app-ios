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
    struct JointAccount {
        struct Member: Decodable {
            let name: String
            let address: String
            let role: JointAccountMemberRole
            /// The invite this member redeemed to take their slot, which is what lets the creator tell which invite
            /// went to whom while the account is still filling up. The creator's own slot never had one, and an
            /// activated account is reported without them: by then they have all served their purpose.
            let inviteId: String?
        }

        struct Invite: Decodable {
            let id: String
        }

        /// The names matched here are the wire contract. What the stages mean is `JointAccountStatus`'s to say.
        enum Status: String {
            case pending
            case confirming
            case active
            case cancelled
        }

        let cryptoAccountId: String
        let membersCount: Int
        let threshold: Int
        /// Absent until every slot is taken.
        let safeAddress: String?
        /// Reported by every answer; nil for a stage this version has never heard of — see `init(from:)`.
        let status: Status?
        let members: [Member]
        /// Only ever answers creating the account — see `StoredJointAccountInvite`.
        let invites: [Invite]?
        /// The unfinished operations, at most one per network.
        let operations: [Operation]?
    }
}

// MARK: - Decodable

extension JointAccountsDTO.Response.JointAccount: Decodable {
    private enum CodingKeys: String, CodingKey {
        case cryptoAccountId
        case membersCount
        case threshold
        case safeAddress
        case status
        case members
        case invites
        case operations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        cryptoAccountId = try container.decode(String.self, forKey: .cryptoAccountId)
        membersCount = try container.decode(Int.self, forKey: .membersCount)
        threshold = try container.decode(Int.self, forKey: .threshold)
        safeAddress = try container.decodeIfPresent(String.self, forKey: .safeAddress)
        // The field itself is required, and an answer arriving without it is the contract broken rather than the
        // contract grown — only the name inside it is allowed to be one this version has never heard of
        status = Status(rawValue: try container.decode(String.self, forKey: .status))
        members = try container.decode([Member].self, forKey: .members)
        invites = try container.decodeIfPresent([Invite].self, forKey: .invites)
        // Spelled out in full: from an extension of the nested type, the bare name resolves to `Foundation.Operation`
        operations = try container.decodeIfPresent([JointAccountsDTO.Response.Operation].self, forKey: .operations)
    }
}
