//
//  EtherscanAPIError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum EtherscanAPIError: Error {
    case maxRateLimitReached
    case endOfTransactionHistoryReached
    case unknown
}
