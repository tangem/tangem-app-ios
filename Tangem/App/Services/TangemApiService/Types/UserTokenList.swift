//
//  UserTokenList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemSdk.DerivationPath

/// The API model for the`user-tokens/:key/` routing
struct UserTokenList: Codable {
    let tokens: [Token]
    
    private let version: Int
    private let group: GroupType
    private let sort: SortType

    init(
        tokens: [UserTokenList.Token],
        version: Int = 0,
        group: UserTokenList.GroupType = .none,
        sort: UserTokenList.SortType = .manual
    ) {
        self.tokens = tokens
        self.version = version
        self.group = group
        self.sort = sort
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        tokens = try container.decode([Token].self, forKey: .tokens)

        let groupKey = try container.decodeIfPresent(String.self, forKey: .group) ?? ""
        group = GroupType(rawValue: groupKey) ?? .none

        let sortKey = try container.decodeIfPresent(String.self, forKey: .sort) ?? ""
        sort = SortType(rawValue: sortKey) ?? .manual
    }
}

extension UserTokenList {
    enum CodingKeys: CodingKey {
        case version
        case group
        case sort
        case tokens
    }

    struct Token: Codable {
        let id: String?
        let networkId: String
        let name: String
        let symbol: String
        let decimals: Int
        let derivationPath: DerivationPath?
        let contractAddress: String?
    }

    enum GroupType: String, Codable {
        case none
        case network
        case token
    }

    enum SortType: String, Codable {
        case balance
        case manual
        case marketCap = "marketcap"
    }
}
