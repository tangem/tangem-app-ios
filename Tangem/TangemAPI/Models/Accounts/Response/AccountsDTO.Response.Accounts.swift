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

        struct Wallet: Decodable {
            let version: Int
            let group: GroupType
            let sort: SortType
            let totalAccounts: Int
            let totalArchivedAccounts: Int
        }

        struct Token: Codable, Hashable {
            let id: String?
            let networkId: String
            let name: String
            let symbol: String
            let decimals: Int
            let derivationPath: String?
            let contractAddress: String?
        }

        struct Account: Decodable {
            let id: String
            /// Nil, if the account uses a localized name.
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
