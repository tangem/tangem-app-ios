//
//  AlephiumUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AlephiumUtils {
    func isNotFromFuture(lockTime: Double) -> Bool {
        let nowMillis = Date().timeIntervalSince1970 * 1000
        return lockTime <= nowMillis
    }
}
