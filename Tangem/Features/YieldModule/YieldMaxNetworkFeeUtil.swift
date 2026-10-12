//
//  YieldMaxNetworkFeeUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk

struct YieldMaxNetworkFeeUtil {
    func maxNetworkFee(
        maxFeeNative: Decimal,
        coinPrice: Decimal,
        tokenPrice: Decimal,
        token: Token
    ) throws -> BigUInt {
        guard tokenPrice > 0 else {
            throw YieldModuleError.maxNetworkFeeNotFound
        }

        let maxFeeToken = maxFeeNative * coinPrice / tokenPrice

        guard maxFeeToken > 0 else {
            throw YieldModuleError.maxNetworkFeeNotFound
        }

        return EthereumUtils.mapToBigUInt(maxFeeToken * token.decimalValue)
    }
}
