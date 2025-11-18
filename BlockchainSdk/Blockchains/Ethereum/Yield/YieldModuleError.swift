//
//  YieldModuleError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum YieldModuleError: Error {
    case unableToParseData
    case unsupportedBlockchain
    case noYieldContractFound
    case feeNotFound
    case yieldIsAlreadyActive
    case inconsistentState
    case yieldIsNotActive
    case maxNetworkFeeNotFound
    case minimalTopUpAmountNotFound
}
