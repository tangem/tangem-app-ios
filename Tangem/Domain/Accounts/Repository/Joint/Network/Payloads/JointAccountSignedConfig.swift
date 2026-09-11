//
//  JointAccountSignedConfig.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// The settings every member of a joint account shares, settled when it is created and never changed afterwards.
/// - Warning: Signed twice over: the creator signs it into the account, and whoever is invited reads it out of the
/// invite and signs it back, which the endpoint rejects the slightest difference in. So one type both decodes the
/// invite and encodes the joining payload — two descriptions of the same fields would be free to drift.
/// - Warning: What is signed back are the fields named here and nothing else, so a field the endpoint adds to the
/// settings is dropped on the way through and turns every join into a conflict until this type learns about it.
struct JointAccountSignedConfig: Codable, Equatable {
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
