//
//  JointAccountInvite.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// - Warning: The account's only access secret — whoever holds one takes a slot. Handed out solely in the answer to
/// creating the account, never readable afterwards, and neither revocable nor reissuable, so losing one costs the
/// creator the ability to invite anyone at all.
struct JointAccountInvite: Codable, Equatable {
    /// 32 bytes in upper-case hex.
    let id: String
}
