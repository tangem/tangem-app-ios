//
//  AccountsDTO.Request.UserTokens.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension AccountsDTO.Request {
    // [REDACTED_TODO_COMMENT]
    typealias GroupType = UserTokenList.GroupType

    // [REDACTED_TODO_COMMENT]
    typealias SortType = UserTokenList.SortType

    struct UserTokens: Encodable {
        let tokens: [Token]
        let group: GroupType
        let sort: SortType
        let notifyStatus: Bool
        let version: Int
    }

    struct Token: Encodable {
        let id: String?
        let accountId: String
        let networkId: String
        let name: String
        let symbol: String
        let decimals: Int
        let derivationPath: String?
        let contractAddress: String?
        let addresses: [String]?
    }
}
