//
//  JointAccountsDTO.Response.Operation.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Response {
    /// An unfinished operation. It rides inside its account in the accounts listing, since the contract has no
    /// endpoint for reading operations on their own, and a cancelled one simply disappears from there.
    struct Operation {
        /// A member's answer; only the members that have answered are listed. The ones yet to answer are worked out
        /// from the account's members, matched by address case-insensitively.
        struct Vote {
            /// The names matched here are the wire contract. What the answers mean is
            /// `JointAccountOperation.Signature.State`'s to say.
            /// - Note: The declining answer is not named yet: this version has only ever seen approvals, and a name it
            /// does not know costs the answer alone — see `init(from:)`.
            enum Answer: String {
                case approve
            }

            let address: String
            /// Nil for an answer this version has never heard of — see `init(from:)`.
            let vote: Answer?
            /// ISO 8601. Left as it arrived: the shared decoder insists on fractional seconds, which the contract's
            /// examples do without.
            let votedAt: String
        }

        /// The names matched here are the wire contract. What the stages mean is `JointAccountOperationStatus`'s
        /// to say.
        enum Status: String {
            case awaitingSignatures = "awaiting_signatures"
            case pending
            case executed
            case failed
        }

        /// Issued by the endpoint when the operation is created, and how every later call addresses it.
        let operationId: String
        let chainId: Int
        /// What the co-signers put their signatures over.
        let safeTx: JointAccountsDTO.SafeTx
        /// Nil for a stage this version has never heard of — see `init(from:)`.
        let status: Status?
        /// The address of the member whose signature created the operation.
        let initiator: String
        /// Unix time; swaps expire, plain transfers carry none.
        let deadline: Int?
        let votes: [Vote]?
    }
}

// MARK: - Decodable

extension JointAccountsDTO.Response.Operation: Decodable {
    private enum CodingKeys: String, CodingKey {
        case operationId
        case chainId
        case safeTx
        case status
        case initiator
        case deadline
        case votes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        operationId = try container.decode(String.self, forKey: .operationId)
        chainId = try container.decode(Int.self, forKey: .chainId)
        safeTx = try container.decode(JointAccountsDTO.SafeTx.self, forKey: .safeTx)
        // The field itself is required, and an answer arriving without it is the contract broken rather than the
        // contract grown — only the name inside it is allowed to be one this version has never heard of
        status = try Status(rawValue: container.decode(String.self, forKey: .status))
        initiator = try container.decode(String.self, forKey: .initiator)
        deadline = try container.decodeIfPresent(Int.self, forKey: .deadline)
        votes = try container.decodeIfPresent([Vote].self, forKey: .votes)
    }
}

extension JointAccountsDTO.Response.Operation.Vote: Decodable {
    private enum CodingKeys: String, CodingKey {
        case address
        case vote
        case votedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        address = try container.decode(String.self, forKey: .address)
        vote = try Answer(rawValue: container.decode(String.self, forKey: .vote))
        votedAt = try container.decode(String.self, forKey: .votedAt)
    }
}
