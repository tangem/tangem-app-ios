//
//  FilecoinFeeParameters.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt

struct FilecoinFeeParameters: FeeParameters {
    let gasLimit: Int64
    let gasFeeCap: BigUInt
    let gasPremium: BigUInt
}
