//
//  JointAccountInvitePreview.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// What an invited wallet is shown before it commits to anything: the settings it would be joining under and who is
/// inviting it. The members already inside are not reported.
struct JointAccountInvitePreview: Equatable {
    struct Creator: Equatable {
        let name: String
        /// - Warning: Its letter case carries an EIP-55 checksum rather than identity, so two of these are never
        /// compared as strings.
        let address: String
    }

    let config: JointAccountSignedConfig
    let creator: Creator
}
