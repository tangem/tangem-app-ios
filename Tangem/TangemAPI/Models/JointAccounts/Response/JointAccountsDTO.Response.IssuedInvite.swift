//
//  JointAccountsDTO.Response.IssuedInvite.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Response {
    struct IssuedInvite: Decodable {
        let id: String
        let slot: Int
        let expiresAt: String
    }
}
