//
//  P2PStakingError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum P2PStakingError: Error {
    case apiError(P2PAPIError?)
    case httpError(statusCode: Int)
    case failedToGetFee
    case invalidVault
    case transactionNotFound
    case feeIncreased(newFee: Decimal)
}

public enum P2PAPIError: Int, Error, CaseIterable {
    case insufficientAccountBalance = 127102
    case unknown = -1

    init(apiError: P2PDTO.APIError) {
        switch apiError.code {
        case .none:
            self = .unknown
        case .some(let code):
            self = P2PAPIError.allCases.first(where: { $0.rawValue == code }) ?? .unknown
        }
    }
}
