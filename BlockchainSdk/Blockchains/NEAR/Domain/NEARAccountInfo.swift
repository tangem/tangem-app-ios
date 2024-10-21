//
//  NEARAccountInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum NEARAccountInfo {
    struct Account {
        let accountId: String
        let amount: Amount
        let recentBlockHash: String
        let storageUsageInBytes: Decimal
    }

    case notInitialized
    case initialized(Account)
}
