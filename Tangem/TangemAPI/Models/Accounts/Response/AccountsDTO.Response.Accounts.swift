//
//  AccountsDTO.Response.Accounts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension AccountsDTO.Response {
    struct Accounts: Decodable {
        // [REDACTED_TODO_COMMENT]
        typealias GroupType = UserTokenList.GroupType

        // [REDACTED_TODO_COMMENT]
        typealias SortType = UserTokenList.SortType

        // [REDACTED_TODO_COMMENT]
        typealias Token = UserTokenList.Token

        struct Wallet: Decodable {
            let version: Int
            let group: GroupType
            let sort: SortType
            let totalAccounts: Int
            let totalArchivedAccounts: Int
        }

        struct Account: Decodable {
            let id: String
            let name: String?
            let icon: String
            let iconColor: String
            let derivation: Int
            let tokens: [Token]
        }

        let wallet: Wallet
        let accounts: [Account]
        let unassignedTokens: [Token]
    }
}
