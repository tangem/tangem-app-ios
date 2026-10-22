//
//  JointAccountsDTO.Response.Operation.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Response {
    /// An operation as every endpoint words it. Unfinished, it rides inside its account in the accounts listing,
    /// which a cancelled one simply disappears from; the operations history and the single operation answer
    /// report it in any stage, with the fields `HistoryOperation` adds on top.
    struct Operation {
        /// A member's answer; only the members that have answered are listed. The ones yet to answer are worked out
        /// from the account's members, matched by address case-insensitively.
        struct Vote {
            /// The names matched here are the wire contract. What the answers mean is
            /// `JointAccountOperation.Signature.State`'s to say.
            enum Answer: String {
                case approve
                case reject
            }

            let address: String
            /// Nil for an answer this version has never heard of — see `init(from:)`.
            let vote: Answer?
            /// Nil for a declining answer: a rejection is not signed.
            let signature: String?
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
            /// The initiator called it off, or the refusals put the threshold out of reach. The collected signatures
            /// are dropped with it, and the operation leaves the listing.
            case cancelled
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
        /// How many answers this operation needs, which is the account's threshold at the time it was created.
        let threshold: Int
        let votes: [Vote]?
        /// ISO 8601, left as it arrived — see `Vote.votedAt`.
        let createdAt: String
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
        case threshold
        case votes
        case createdAt
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
        threshold = try container.decode(Int.self, forKey: .threshold)
        votes = try container.decodeIfPresent([Vote].self, forKey: .votes)
        createdAt = try container.decode(String.self, forKey: .createdAt)
    }
}

extension JointAccountsDTO.Response.Operation.Vote: Decodable {
    private enum CodingKeys: String, CodingKey {
        case address
        case vote
        case signature
        case votedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        address = try container.decode(String.self, forKey: .address)
        vote = try Answer(rawValue: container.decode(String.self, forKey: .vote))
        signature = try container.decodeIfPresent(String.self, forKey: .signature)
        votedAt = try container.decode(String.self, forKey: .votedAt)
    }
}
