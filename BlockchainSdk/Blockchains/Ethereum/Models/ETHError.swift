//
//  ETHError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

public enum ETHError: Error, LocalizedError {
    case failedToParseTxCount
    case failedToParseBalance(value: String, address: String, decimals: Int)
    case failedToParseGasLimit
    case failedToParseFeeHistory
    case failedToParseAllowance
    case gasRequiredExceedsAllowance
    case unsupportedFeature

    public var errorDescription: String? {
        switch self {
        case .failedToParseTxCount, .failedToParseAllowance, .failedToParseFeeHistory:
            return Localization.genericErrorCode(errorCodeDescription)
        case .failedToParseBalance(let value, let address, let decimals):
            return "Failed to parse balance: value:\(value), address:\(address), decimals:\(decimals)"
        case .failedToParseGasLimit: // [REDACTED_TODO_COMMENT]
            return Localization.genericErrorCode(errorCodeDescription)
        case .gasRequiredExceedsAllowance:
            return Localization.ethGasRequiredExceedsAllowance
        case .unsupportedFeature:
            return "unsupportedFeature"
        }
    }

    private var errorCodeDescription: String {
        "eth_error \(errorCode)"
    }

    private var errorCode: Int {
        switch self {
        case .failedToParseTxCount:
            return 1
        case .failedToParseBalance:
            return 2
        case .failedToParseGasLimit:
            return 3
        case .failedToParseAllowance:
            return 4
        case .gasRequiredExceedsAllowance:
            return 5
        case .unsupportedFeature:
            return 6
        case .failedToParseFeeHistory:
            return 7
        }
    }
}
