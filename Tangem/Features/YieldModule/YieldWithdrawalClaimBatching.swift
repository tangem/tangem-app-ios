//
//  YieldWithdrawalClaimBatching.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum YieldWithdrawalClaimBatching {
    static func isSupported(blockchain: Blockchain) -> Bool {
        switch blockchain {
        case .avalanche:
            return false
        default:
            return true
        }
    }
}
