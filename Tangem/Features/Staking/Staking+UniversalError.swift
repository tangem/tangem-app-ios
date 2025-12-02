//
//  Staking+UniversalError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemStaking

// `Subsystems`:
// `000` - StakeKitTransactionDispatcher.Error
// `001` - StakeKitMapperError
// `002` - StakeKitHTTPError
// `003` -
// `004` -
// `005` -

extension StakeKitTransactionDispatcher.Error: UniversalError {
    var errorCode: Int {
        switch self {
        case .resultNotFound:
            105000000
        case .stakingUnsupported:
            105000001
        }
    }
}

extension StakeKitMapperError: @retroactive UniversalError {
    public var errorCode: Int {
        switch self {
        case .notImplement:
            105001000
        case .noData:
            105002001
        case .tronTransactionMappingFailed:
            105003001
        }
    }
}

extension StakeKitHTTPError: @retroactive UniversalError {
    public var errorCode: Int {
        switch self {
        case .badStatusCode:
            105002000
        }
    }
}
