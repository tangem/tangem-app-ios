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
@available(iOS, deprecated: 100000.0, message: "Superseded by 'AccountsDTO.Response.Accounts', will be removed in the future ([REDACTED_INFO])")
struct UserTokenList: Codable {
    var tokens: [Token]
    var group: GroupType
    var sort: SortType
    var notifyStatus: Bool?

    /// Name  of  the new wallet
    var name: String?
    /// Type  of  the new wallet
    var type: String?

    private let version: Int

    init(
        tokens: [Token],
        group: GroupType,
        sort: SortType,
        notifyStatus: Bool? = nil,
        version: Int,
        name: String?,
        type: String?
    ) {
        self.tokens = tokens
        self.group = group
        self.sort = sort
        self.notifyStatus = notifyStatus
        self.version = version
        self.name = name
        self.type = type
    }
}

extension UserTokenList {
    @available(iOS, deprecated: 100000.0, message: "Superseded by 'AccountsDTO.Response.Accounts.Token', will be removed in the future ([REDACTED_INFO])")
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

    @available(iOS, deprecated: 100000.0, message: "Superseded by 'AccountsDTO.Response.Accounts.Token', will be removed in the future ([REDACTED_INFO])")
    enum GroupType: String, Codable {
        case none
        case network
    }

    @available(iOS, deprecated: 100000.0, message: "Superseded by 'AccountsDTO.Response.Accounts.Token', will be removed in the future ([REDACTED_INFO])")
    enum SortType: String, Codable {
        case manual
        case balance
    }
}

// MARK: - Constants

private extension UserTokenList {
    enum Constants {
        private static var apiVersion: Int { 0 }
    }
}
