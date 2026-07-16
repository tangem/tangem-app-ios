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
        /// Optional so the v2 `/tokens` endpoint can omit it entirely (contract v1.3 dropped `notifyStatus`
        /// in favor of the dedicated notification-preferences store). The synthesized encoder skips `nil`,
        /// so the v1 endpoint keeps sending a concrete value while v2 sends no field at all — the latter is
        /// enforced at the request boundary by `omittingNotifyStatus()`.
        let notifyStatus: Bool?
        let version: Int

        /// Produced with a concrete `notifyStatus` for the v1 endpoint. The v2 `/tokens` endpoint dropped
        /// the field (contract v1.3), so the v2 request path strips it via this helper before encoding.
        func omittingNotifyStatus() -> Self {
            Self(tokens: tokens, group: group, sort: sort, notifyStatus: nil, version: version)
        }
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
