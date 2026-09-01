//
//  JointAccountConfig.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

/// The rules a joint account is operated by, beyond the name, the icon and the tokens it holds as one of the
/// wallet's own accounts.
struct JointAccountConfig: Equatable {
    /// How many slots the account has, the creator's included.
    let membersCount: Int
    /// How many of the members have to sign an operation for it to go through — the M of an M-of-N account.
    let signersCount: Int
    /// One and the same across every supported EVM network. Absent until every slot is taken.
    let address: String?
    let status: JointAccountStatus
}

// MARK: - CustomStringConvertible protocol conformance

extension JointAccountConfig: CustomStringConvertible {
    var description: String {
        objectDescription(
            "JointAccountConfig",
            userInfo: [
                "membersCount": membersCount,
                "signersCount": signersCount,
                "address": address ?? "none",
                "status": status,
            ]
        )
    }
}
