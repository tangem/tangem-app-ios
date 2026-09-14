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
        /// - Warning: The endpoint keeps these in lower case while the app computes the checksummed form, so two of
        /// these are only ever compared case-insensitively, never as strings.
        let address: String
    }

    let config: JointAccountSignedConfig
    let creator: Creator
}
