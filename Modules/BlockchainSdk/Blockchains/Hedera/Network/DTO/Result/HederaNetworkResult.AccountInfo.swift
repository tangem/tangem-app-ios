//
//  HederaNetworkResult.AccountInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension HederaNetworkResult {
    struct AccountInfo: Decodable {
        /// Network entity ID in the format of `shard.realm.num`.
        let account: String?
        /// RFC4648 no-padding base32 encoded account alias.
        let alias: String?
        /// A network entity encoded as an EVM address in hex.
        let evmAddress: String?
    }
}
