//
//  JointAccountsDTO.List.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.List {
    /// Every joint account the wallet takes part in, archived ones included — without them a free derivation index
    /// cannot be found.
    /// - Note: An empty list is an empty list and a 200, never a 404.
    struct Response: Decodable {
        let jointAccounts: [JointAccountsDTO.JointAccount]
    }
}
