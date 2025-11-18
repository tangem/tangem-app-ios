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
@available(iOS, deprecated: 100000.0, message: "Superseded by 'AccountsDTO.Response.Accounts', will be removed in the future")
struct UserTokenList: Codable {
    var tokens: [Token]
    var group: GroupType
    var sort: SortType
    var notifyStatus: Bool?

    private let version: Int

    init(
        tokens: [Token],
        group: GroupType,
        sort: SortType,
        notifyStatus: Bool? = nil,
        version: Int
    ) {
        self.tokens = tokens
        self.group = group
        self.sort = sort
        self.notifyStatus = notifyStatus
        self.version = version
    }
}

extension UserTokenList {
    static var initialVersion: Int { 0 }

    init(
        tokens: [Token],
        group: GroupType,
        sort: SortType,
        notifyStatus: Bool? = nil
    ) {
        self.init(
            tokens: tokens,
            group: group,
            sort: sort,
            notifyStatus: notifyStatus,
            version: Self.initialVersion
        )
    }
}

extension UserTokenList {
    @available(iOS, deprecated: 100000.0, message: "Superseded by 'AccountsDTO.Response.Accounts.Token', will be removed in the future")
    struct Token: Codable, Hashable {
        let id: String?
        let networkId: String
        let name: String
        let symbol: String
        let decimals: Int
        let derivationPath: DerivationPath?
        let contractAddress: String?
        let addresses: [String]?
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
