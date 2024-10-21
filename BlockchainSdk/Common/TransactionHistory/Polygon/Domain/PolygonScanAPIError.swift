//
//  PolygonScanAPIError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum PolygonScanAPIError: Error {
    case maxRateLimitReached
    case endOfTransactionHistoryReached
    case unknown
}
