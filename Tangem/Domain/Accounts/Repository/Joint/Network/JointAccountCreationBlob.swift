//
//  JointAccountCreationBlob.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountCreationBlob {
    let payload: JointAccountCreationPayload
    /// - Warning: The bytes that were signed are not sent, so this side's canonical form has to match the endpoint's
    /// on its own.
    let signature: Data
}

/// - Warning: The endpoint canonicalises this exactly as it arrives and verifies the signature over the result, so
/// neither the field names, nor the way they nest, nor the way they are encoded can change without agreeing it with
/// the backend.
struct JointAccountCreationPayload: Codable, Equatable {
    /// Settled once and never again.
    struct Config: Codable, Equatable {
        /// From 1 to 20 characters, kept exactly as typed.
        let name: String
        /// Names out of the same icon and colour sets the wallet's own accounts are drawn from.
        let icon: String
        let iconColor: String
        /// How many slots the account has, from 2 to 5, the creator's included.
        let membersCount: Int
        /// How many members have to sign an operation for it to be executed, from 1 to `membersCount`.
        let threshold: Int
    }

    struct Creator: Codable, Equatable {
        /// Repeats what the request is addressed to on purpose: the path only routes it, so without this the
        /// signature would not be bound to a wallet and an intercepted payload could be replayed under someone else's.
        let walletId: String
        /// The name the creator is known by inside the account, from 1 to 25 characters.
        let name: String
        /// The owner address, which every member sees.
        let address: String
        /// Which local account of the creator this joint account corresponds to, as `m/44'/60'/888888'/0/{derivation}`.
        /// The backend keeps it to itself and syncs the token list between the members by it.
        let derivation: Int
    }

    let config: Config
    let creator: Creator
}
