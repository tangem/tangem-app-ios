//
//  JointAccountPolicy.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

/// The rules a joint account is operated by, beyond the name, the icon and the tokens it holds as one of the
/// wallet's own accounts.
/// - Note: Fixed when the account is created, unlike the status, which is how far the account has come since —
/// see `JointAccountModel.status`.
struct JointAccountPolicy: Equatable {
    /// How many slots the account has, the creator's included.
    let membersCount: Int
    /// How many of the members have to sign an operation for it to go through — the M of an M-of-N account.
    let signersCount: Int
}

// MARK: - CustomStringConvertible protocol conformance

extension JointAccountPolicy: CustomStringConvertible {
    var description: String {
        objectDescription(
            "JointAccountPolicy",
            userInfo: [
                "membersCount": membersCount,
                "signersCount": signersCount,
            ]
        )
    }
}
