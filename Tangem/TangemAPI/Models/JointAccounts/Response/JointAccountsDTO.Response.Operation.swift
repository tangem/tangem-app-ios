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
    struct Operation: Decodable {
        /// A member's answer; only the members that have answered are listed. The ones yet to answer are worked out
        /// from the account's members, matched by address case-insensitively.
        struct Signature: Decodable {
            let address: String
            /// `signed` or `declined`.
            let state: String
            /// ISO 8601. Left as it arrived: the shared decoder insists on fractional seconds, which the contract's
            /// examples do without.
            let at: String
        }

        /// Issued by the endpoint when the operation is created, and how every later call addresses it.
        let operationId: String
        let chainId: Int
        /// What the co-signers put their signatures over.
        let safeTx: JointAccountsDTO.SafeTx
        /// `awaiting_signatures`, `pending`, `executed`, `failed` or `expired`. Left as it arrived, since the set
        /// goes on growing.
        let status: String
        /// The address of the member whose signature created the operation.
        let initiator: String
        /// Unix time; swaps expire, plain transfers carry none.
        let deadline: Int?
        let signatures: [Signature]
    }
}
