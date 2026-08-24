//
//  JointAccountSignedMember.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// How a wallet introduces itself when it takes a slot, whether by creating the account or by joining one.
struct JointAccountSignedMember: Codable, Equatable {
    /// Repeats what the request is addressed to on purpose: the path only routes it, so without this the signature
    /// would not be bound to a wallet and an intercepted payload could be replayed under someone else's.
    let walletId: String
    /// The name this member is known by inside the account, from 1 to 25 characters.
    let name: String
    /// The owner address, which every member sees.
    let address: String
    /// Which local account of this wallet the joint one corresponds to, as `m/44'/60'/888888'/0/{derivation}`.
    /// The backend keeps it to itself and syncs the token list between the members by it.
    /// - Warning: Read off the wallet's own count of joint accounts as the request is made, and the account's from then
    /// on. Every member holds a different one, so whatever signs for the account afterwards derives at the index it was
    /// created or joined with rather than at whatever that count has grown to since.
    let derivation: Int
}
