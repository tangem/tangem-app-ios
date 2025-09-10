//
//  AccountsDTO.Request.Accounts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension AccountsDTO.Request {
    struct Accounts: Encodable {
        struct Account: Encodable {
            let id: String
            let name: String?
            let icon: String
            let iconColor: String
            let derivation: Int
        }

        let accounts: [Account]
    }
}
