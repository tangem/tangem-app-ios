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
        version: Int,
        group: GroupType,
        sort: SortType
    ) {
        self.tokens = tokens
        self.version = version
        self.group = group
        self.sort = sort
    }
}

extension UserTokenList {
    struct Token: Codable, Hashable {
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
    }

    enum SortType: String, Codable {
        case manual
        case balance
    }
}
