//
//  JointAccountsDTO.Response.JointAccounts.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Response {
    /// Every joint account the wallet takes part in, except the archived ones: those are filtered out by the
    /// wallet's own entry for them and come back from the archived accounts endpoint instead.
    /// - Note: An empty list is an empty list and a 200, never a 404.
    struct JointAccounts: Decodable {
        let jointAccounts: [JointAccount]
    }
}
