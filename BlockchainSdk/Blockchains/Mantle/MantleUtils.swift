//
//  MantleUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public enum MantleUtils {
    public static let feeGasLimitMultiplier = 1.6
    static let signGasLimitMultiplier = 0.7

    public static func multiplyGasLimit(_ gasLimit: Int, with multiplier: Double) -> BigUInt {
        multiplyGasLimit(BigUInt(gasLimit), with: multiplier)
    }

    static func multiplyGasLimit(_ gasLimit: BigUInt, with multiplier: Double) -> BigUInt {
        BigUInt(ceil(Double(gasLimit) * multiplier))
    }
}
