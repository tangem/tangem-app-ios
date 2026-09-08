//
//  JointAccountJoinConfig.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct JointAccountJoinConfig {
    let inviteId: String
    /// Signed as it came from the invite preview: the creator settled these terms, and the signature covers them.
    let signedConfig: JointAccountSignedConfig
    let memberName: String
    let derivationIndex: Int
}
