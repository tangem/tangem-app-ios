//
//  JointAccountsDTO.Request.IssueInvite.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Request {
    struct IssueInvite: Encodable {
        let cryptoAccountId: String
        let slot: Int
    }
}
