//
//  ETHError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

public enum ETHError: LocalizedError {
    case failedToParseTxCount
    case failedToParseBalance(value: String, address: String, decimals: Int)
    case failedToParseGasLimit
    case failedToParseFeeHistory
    case failedToParseAllowance
    case gasRequiredExceedsAllowance
    case unsupportedFeature
    case failedToGetChecksumAddress
    case chainIdNotFound
    case invalidSourceAddress

    public var errorDescription: String? {
        switch self {
        case .failedToParseBalance(let value, let address, let decimals):
            return "Failed to parse balance: value:\(value), address:\(address), decimals:\(decimals)"
        case .gasRequiredExceedsAllowance:
            return Localization.ethGasRequiredExceedsAllowance
        default:
            return Localization.genericErrorCode(errorCode)
        }
    }
}
