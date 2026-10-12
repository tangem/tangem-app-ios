//
//  JointAccountsDTO.Response.InvitePreview.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Response {
    struct InvitePreview: Decodable {
        struct Creator: Decodable {
            let name: String
            let address: String
        }

        let config: JointAccountSignedConfig
        let creator: Creator
    }
}
