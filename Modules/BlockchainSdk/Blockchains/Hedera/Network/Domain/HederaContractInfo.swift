//
//  HederaContractInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct HederaContractInfo {
    /// Network entity ID in the format of `shard.realm.num`.
    let contractId: String?
    let evmAddress: String?
}
