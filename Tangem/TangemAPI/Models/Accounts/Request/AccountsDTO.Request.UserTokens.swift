//
//  AccountsDTO.Request.UserTokens.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension AccountsDTO.Request {
    struct UserTokens: Encodable {
        let tokens: [Token]
        let group: AccountsDTO.GroupType
        let sort: AccountsDTO.SortType
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
        let dynamicAddressesEnabled: Bool?
    }
}
