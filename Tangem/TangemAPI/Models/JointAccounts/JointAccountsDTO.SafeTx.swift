//
//  JointAccountsDTO.SafeTx.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO {
    /// The transaction the members sign together, worded exactly as the Safe contracts define it. The one shape both
    /// directions share: creating, signing and rejecting an operation all send it, and the accounts listing brings it
    /// back for the co-signers to put their signatures over.
    struct SafeTx: Codable {
        let to: String
        let value: String
        let data: String
        /// Only `.call`; a `.delegateCall` is turned away by the endpoint.
        let operation: Operation
        let safeTxGas: String
        /// Includes deploying the Safe when the network does not have it yet.
        let baseGas: String
        let gasPrice: String
        /// From the endpoint's allowlist.
        let gasToken: String
        /// The Tangem treasury.
        let refundReceiver: String
        /// The Safe's on-chain nonce in the network the operation belongs to, which is what makes two unfinished
        /// operations in one network mutually exclusive.
        let nonce: String
    }
}

extension JointAccountsDTO.SafeTx {
    /// The two ways a Safe executes a transaction, numbered as the contract numbers them.
    enum Operation: Int, Codable {
        case call = 0
        case delegateCall = 1
    }
}
