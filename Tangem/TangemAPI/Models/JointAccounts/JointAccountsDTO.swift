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

// MARK: - Shared

/// Shared DTO types used by more than one endpoint.
extension JointAccountsDTO {
    /// The account as every endpoint describes it, whether it has just been created, joined, activated or merely read.
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
        let safeAddress: String?
        let status: JointAccountStatus
        let members: [Member]
        /// Only ever answers creating the account — see `JointAccountInvite`.
        let invites: [Invite]?
    }

    struct SignedRequest<Payload: Encodable>: Encodable {
        /// - Warning: Encoded exactly as the signer left it — see `JointAccountSignedBlob`.
        let payload: Payload
        /// `0x` followed by 130 hex characters.
        let signature: String
    }
}

// MARK: - Endpoints

/// A second-level namespace, per endpoint.
extension JointAccountsDTO {
    enum Create {
        typealias Request = SignedRequest<JointAccountCreationPayload>

        /// The account as reading it would describe it, with the invites filled in.
        typealias Response = JointAccount
    }

    enum List {
        /// Every joint account the wallet takes part in, except the archived ones: those are filtered out by the
        /// wallet's own entry for them and come back from the archived accounts endpoint instead.
        /// - Note: An empty list is an empty list and a 200, never a 404.
        struct Response: Decodable {
            let jointAccounts: [JointAccount]
        }
    }

    enum InvitePreview {
        struct Response: Decodable {
            struct Creator: Decodable {
                let name: String
                let address: String
            }

            let config: JointAccountSignedConfig
            let creator: Creator
        }
    }

    enum Join {
        typealias Request = SignedRequest<JointAccountJoinPayload>

        /// The account with the slot this call took, and — if it was the last free one — the address and the status the
        /// endpoint worked out from the full composition.
        typealias Response = JointAccount
    }

    enum Activate {
        typealias Request = SignedRequest<JointAccountActivationPayload>

        typealias Response = JointAccount
    }
}
