//
//  KoinosResourceLimitData.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt

struct KoinosResourceLimitData {
    let diskStorageLimit: BigUInt
    let diskStorageCost: BigUInt
    let networkBandwidthLimit: BigUInt
    let networkBandwidthCost: BigUInt
    let computeBandwidthLimit: BigUInt
    let computeBandwidthCost: BigUInt
}
