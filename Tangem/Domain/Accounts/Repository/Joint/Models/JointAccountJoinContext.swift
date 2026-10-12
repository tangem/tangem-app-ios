//
//  JointAccountJoinContext.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct JointAccountJoinContext {
    let inviteId: String
    /// Comes from the invite preview and is signed as is — the terms were settled by whoever created the account.
    let signedConfig: JointAccountSignedConfig
    /// How the other members will see this wallet in the account.
    let memberName: String
}
