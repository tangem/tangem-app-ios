//
//  AccountsDTO.Response.ArchivedAccounts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension AccountsDTO.Response {
    struct ArchivedAccounts: Decodable {
        struct ArchivedAccount: Decodable {
            let id: String
            /// Nil, if the account uses a localized name.
            let name: String?
            let icon: String
            let iconColor: String
            let derivation: Int
            let totalTokens: Int
            let totalNetworks: Int
        }

        let archivedAccounts: [ArchivedAccount]
    }
}
