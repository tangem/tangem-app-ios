//
//  EthereumOptimisticRollupConstants.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum EthereumOptimisticRollupConstants {
    static let defaultL1GasPriceOracleSmartContractAddress = "0x420000000000000000000000000000000000000F"
    static let scrollL1GasPriceOracleSmartContractAddress = "0x5300000000000000000000000000000000000002"

    static let defaultL1GasFeeMultiplier: Decimal = 1.0
    /// Scroll requires extra multiplier for L1 because of incorrect amount from oracle contract.
    static let scrollL1GasFeeMultiplier: Decimal = 3.0
}
