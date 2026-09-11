//
//  P2PStakingError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum P2PStakingError: Error {
    case apiError(code: Int?, message: String?)
    case httpError(statusCode: Int)
    case regionUnavailable
    case failedToGetFee
    case invalidVault
    case transactionNotFound
    case feeIncreased(newFee: Decimal)
}
